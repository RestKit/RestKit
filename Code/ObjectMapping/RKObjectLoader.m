//
//  RKObjectLoader.m
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "../CoreData/RKManagedObjectStore.h"
#import "RKObjectLoader.h"
#import "RKObjectManager.h"
#import "Errors.h"
#import "RKManagedObject.h"
#import "RKURL.h"

@interface RKObjectLoader (Private)
- (void)loadObjectsFromResponse:(RKResponse*)response;
@end

@implementation RKObjectLoader

@synthesize mapper = _mapper, delegate = _delegate, request = _request, response = _response,
			objectClass = _objectClass, source = _source, keyPath = _keyPath, managedObjectStore = _managedObjectStore;

+ (id)loaderWithMapper:(RKObjectMapper*)mapper request:(RKRequest*)request delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	return [[[self alloc] initWithMapper:mapper request:request delegate:delegate] autorelease];
}

- (id)initWithMapper:(RKObjectMapper*)mapper request:(RKRequest*)request delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	if (self = [self init]) {
		_mapper = [mapper retain];
		self.request = request;
		self.delegate = delegate;
		self.managedObjectStore = nil;
	}
	
	return self;
}

- (void)dealloc {
	_request.delegate = nil;
	[_mapper release];
	[_request release];
	[_response release];
	[_keyPath release];
	self.managedObjectStore = nil;
	[super dealloc];
}

- (void)setRequest:(RKRequest *)request {
	[request retain];
	[_request release];
	_request = request;
	
	_request.delegate = self;
	_request.callback = @selector(loadObjectsFromResponse:);
}

#pragma mark RKRequest Proxy Methods

- (NSURL*)URL {
	return self.request.URL;
}

- (RKRequestMethod)method {
	return self.request.method;
}

- (void)setMethod:(RKRequestMethod)method {
	self.request.method = method;
}

- (NSObject<RKRequestSerializable>*)params {
	return self.request.params;
}

- (void)setParams:(NSObject<RKRequestSerializable>*)params {
	self.request.params = params;
}

- (NSObject<RKObjectMappable>*)source {
	return (NSObject<RKObjectMappable>*)self.request.userData;
}

- (void)setSource:(NSObject<RKObjectMappable>*)source {
	self.request.userData = source;
}

- (void)send {
	[self retain];
	[self.request send];
}

- (void)sendSynchronously {
	[self retain];
	RKResponse* response = [self.request sendSynchronously];
	[self loadObjectsFromResponse:response];
}

#pragma mark Response Processing

- (BOOL)encounteredErrorWhileProcessingRequest:(RKResponse*)response {
	if ([response isFailure]) {
		[_delegate objectLoader:self didFailWithError:response.failureError];
		[self release];
		return YES;
	} else if ([response isError]) {
		[_delegate objectLoader:self didFailWithError:[_mapper parseErrorFromString:[response bodyAsString]]];
		[self release];
		return YES;
	}
	
	return NO;
}

- (void)informDelegateOfObjectLoadWithInfoDictionary:(NSDictionary*)dictionary {
	NSArray* models = [dictionary objectForKey:@"models"];
	[dictionary release];
	
	// NOTE: The models dictionary may contain NSManagedObjectID's from persistent objects
	// that were model mapped on a background thread. We look up the objects by ID and then
	// notify the delegate that the operation has completed.
	NSMutableArray* objects = [NSMutableArray arrayWithCapacity:[models count]];
	for (id object in models) {
		if ([object isKindOfClass:[NSManagedObjectID class]]) {
			[objects addObject:[self.managedObjectStore objectWithID:(NSManagedObjectID*)object]];
		} else {
			[objects addObject:object];
		}
	}
	
	[_delegate objectLoader:self didLoadObjects:[NSArray arrayWithArray:objects]];
	[self release];
}

- (void)informDelegateOfObjectLoadErrorWithInfoDictionary:(NSDictionary*)dictionary {
	NSError* error = [dictionary objectForKey:@"error"];
	[dictionary release];
	
	NSLog(@"[RestKit] RKObjectLoader: Error saving managed object context: error=%@ userInfo=%@", error, error.userInfo);
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  [error localizedDescription], NSLocalizedDescriptionKey,
							  nil];		
	NSError *rkError = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectLoaderRemoteSystemError userInfo:userInfo];
	
	[_delegate objectLoader:self didFailWithError:rkError];
	[self release];
}


- (void)processLoadModelsInBackground:(RKResponse *)response {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];	
	RKManagedObjectStore* objectStore = self.managedObjectStore;
	
	NSLog(@"The response body is %@", [response bodyAsString]);
	
	// If the request was sent through a model, we map the results back into that object
	// TODO: Note that this assumption may not work in all cases, other approaches?
	// The issue is that not specifying the object results in new objects being created
	// rather than mapping back into the original. This is a problem for create (POST) operations.
	NSArray* results = nil;
	id mainThreadModel = response.request.userData;	// The object dispatching the request
	if (mainThreadModel) {
		if ([mainThreadModel isKindOfClass:[NSManagedObject class]]) {
			NSManagedObjectID* modelID = [(NSManagedObject*)mainThreadModel objectID];
			NSManagedObject* backgroundThreadModel = [self.managedObjectStore objectWithID:modelID];
			[_mapper mapObject:backgroundThreadModel fromString:[response bodyAsString]];
			results = [NSArray arrayWithObject:backgroundThreadModel];
		} else {
			[_mapper mapObject:mainThreadModel fromString:[response bodyAsString]];
			results = [NSArray arrayWithObject:mainThreadModel];
		}
	} else {
		id result = [_mapper mapFromString:[response bodyAsString] toClass:self.objectClass keyPath:_keyPath];
		if ([result isKindOfClass:[NSArray class]]) {
			results = (NSArray*)result;
		} else {
			// Using arrayWithObjects: instead of arrayWithObject:
			// so that in the event result is nil, then we get empty array instead of exception for trying to insert nil.
			results = [NSArray arrayWithObjects:result, nil];
		}
		
		if (objectStore && [objectStore managedObjectCache]) {
			if ([self.URL isKindOfClass:[RKURL class]]) {
				RKURL* rkURL = (RKURL*)self.URL;
				NSArray* fetchRequests = [[objectStore managedObjectCache] fetchRequestsForResourcePath:rkURL.resourcePath];
				NSArray* cachedObjects = [RKManagedObject objectsWithFetchRequests:fetchRequests];			
				for (id object in cachedObjects) {
					if ([object isKindOfClass:[RKManagedObject class]]) {
						if (NO == [results containsObject:object]) {
							[[objectStore managedObjectContext] deleteObject:object];
						}
					}
				}
			}
		}
	}
	
	// Before looking up NSManagedObjectIDs, need to save to ensure we do not have
	// temporary IDs for new objects prior to handing the objectIDs across threads
	NSError* error = [objectStore save];
	if (nil != error) {
		NSDictionary* infoDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:response, @"response", error, @"error", nil] retain];
		[self performSelectorOnMainThread:@selector(informDelegateOfObjectLoadErrorWithInfoDictionary:) withObject:infoDictionary waitUntilDone:NO];		
	} else {
		// NOTE: Passing Core Data objects across threads is not safe. 
		// Iterate over each model and coerce Core Data objects into ID's to pass across the threads.
		// The object ID's will be deserialized back into objects on the main thread before the delegate is called back
		NSMutableArray* models = [NSMutableArray arrayWithCapacity:[results count]];
		for (id object in results) {
			if ([object isKindOfClass:[NSManagedObject class]]) {
				[models addObject:[(NSManagedObject*)object objectID]];
			} else {
				[models addObject:object];			 
			}
		}		
		
		NSDictionary* infoDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:response, @"response", models, @"models", nil] retain];
		[self performSelectorOnMainThread:@selector(informDelegateOfObjectLoadWithInfoDictionary:) withObject:infoDictionary waitUntilDone:NO];
	}

	[pool release];
}

- (void)loadObjectsFromResponse:(RKResponse*)response {
	_response = [response retain];
	
	if (NO == [self encounteredErrorWhileProcessingRequest:response] && [response isSuccessful]) {
		[self performSelectorInBackground:@selector(processLoadModelsInBackground:) withObject:response];
	} else {
		// TODO: What do we do if this is not a 200, 4xx or 5xx response? Need new delegate method...
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// RKRequestDelegate
//
// If our delegate responds to the messages, forward them back...

- (void)requestDidStartLoad:(RKRequest*)request {
	if ([_delegate respondsToSelector:@selector(requestDidStartLoad:)]) {
		[_delegate requestDidStartLoad:request];
	}
}

- (void)requestDidFinishLoad:(RKRequest*)request {
	if ([_delegate respondsToSelector:@selector(requestDidFinishLoad:)]) {
		[(NSObject<RKRequestDelegate>*)_delegate requestDidFinishLoad:request];
	}
}

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	if ([_delegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
		[(NSObject<RKRequestDelegate>*)_delegate request:request didFailLoadWithError:error];
	}
}

- (void)requestDidCancelLoad:(RKRequest*)request {
	[self release];
	if ([_delegate respondsToSelector:@selector(requestDidCancelLoad:)]) {
		[(NSObject<RKRequestDelegate>*)_delegate requestDidCancelLoad:request];
	}
}

@end
