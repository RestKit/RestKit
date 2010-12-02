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

@synthesize mapper = _mapper, objectLoaderDelegate = _objectLoaderDelegate, response = _response,
			objectClass = _objectClass, targetObject = _targetObject, keyPath = _keyPath, managedObjectStore = _managedObjectStore;

+ (id)loaderWithResourcePath:(NSString*)resourcePath mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	return [[[self alloc] initWithResourcePath:resourcePath mapper:mapper delegate:delegate] autorelease];
}

- (id)initWithResourcePath:(NSString*)resourcePath mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	if (self = [self initWithURL:[[RKClient sharedClient] URLForResourcePath:resourcePath] delegate:self]) {
		_mapper = [mapper retain];
		self.objectLoaderDelegate = delegate;
		self.managedObjectStore = nil;
		_targetObjectID = nil;
		
		[[RKClient sharedClient] setupRequest:self];
	}
	return self;
}

- (void)dealloc {
	self.delegate = nil;
	self.objectLoaderDelegate = nil;
	[self cancel];
	[_mapper release];
	[_response release];
	[_keyPath release];
	self.managedObjectStore = nil;
	[_targetObjectID release];
	_targetObjectID = nil;
	[super dealloc];
}

- (void)setTargetObject:(NSObject<RKObjectMappable>*)targetObject {
	[_targetObject release];
	_targetObject = nil;
	_targetObject = [targetObject retain];
	
	[_targetObjectID release];
	_targetObjectID = nil;
	
	if ([targetObject isKindOfClass:[NSManagedObject class]]) {
		_targetObjectID = [[(NSManagedObject*)targetObject objectID] retain];
	}
}


#pragma mark Response Processing

- (BOOL)encounteredErrorWhileProcessingRequest:(RKResponse*)response {
	if ([response isFailure]) {
		[_objectLoaderDelegate objectLoader:self didFailWithError:response.failureError];
		return YES;
	} else if ([response isError]) {
		if ([response isJSON]) {
			[_objectLoaderDelegate objectLoader:self didFailWithError:[_mapper parseErrorFromString:[response bodyAsString]]];
		} else {
			if ([_objectLoaderDelegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
				[_objectLoaderDelegate objectLoaderDidLoadUnexpectedResponse:self];
			}
		}		
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
	
	[_objectLoaderDelegate objectLoader:self didLoadObjects:[NSArray arrayWithArray:objects]];
}

- (void)informDelegateOfObjectLoadErrorWithInfoDictionary:(NSDictionary*)dictionary {
	NSError* error = [dictionary objectForKey:@"error"];
	[dictionary release];
	
	NSLog(@"[RestKit] RKObjectLoader: Error saving managed object context: error=%@ userInfo=%@", error, error.userInfo);
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  [error localizedDescription], NSLocalizedDescriptionKey,
							  nil];		
	NSError *rkError = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectLoaderRemoteSystemError userInfo:userInfo];
	
	[_objectLoaderDelegate objectLoader:self didFailWithError:rkError];
}


- (void)processLoadModelsInBackground:(RKResponse *)response {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];	
	RKManagedObjectStore* objectStore = self.managedObjectStore;
	
	/**
	 * If this loader is bound to a particular object, then we map
	 * the results back into the instance. This is used for loading and updating
	 * individual object instances via getObject & friends.
	 */
	NSArray* results = nil;
	if (self.targetObject) {
		if (_targetObjectID) {
			NSManagedObject* backgroundThreadModel = [self.managedObjectStore objectWithID:_targetObjectID];
			[_mapper mapObject:backgroundThreadModel fromString:[response bodyAsString]];
			results = [NSArray arrayWithObject:backgroundThreadModel];
		} else {
			[_mapper mapObject:self.targetObject fromString:[response bodyAsString]];
			results = [NSArray arrayWithObject:self.targetObject];
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

///////////////////////////////////////////////////////////////////////////////////////////////////
// RKRequestDelegate
//
// If our delegate responds to the messages, forward them back...

- (void)requestDidStartLoad:(RKRequest*)request {
	if ([_objectLoaderDelegate respondsToSelector:@selector(requestDidStartLoad:)]) {
		[_objectLoaderDelegate requestDidStartLoad:request];
	}
}

- (void)requestDidFinishLoad:(RKRequest*)request withResponse:(RKResponse*)response {
	_response = [response retain];
	
	if (NO == [self encounteredErrorWhileProcessingRequest:response]) {
		// TODO: When other mapping formats are supported, unwind this assumption...
		if ([response isSuccessful] && [response isJSON]) {
			[self performSelectorInBackground:@selector(processLoadModelsInBackground:) withObject:response];
		} else {
			NSLog(@"Encountered unexpected response code: %d (MIME Type: %@)", response.statusCode, response.MIMEType);
			if ([_objectLoaderDelegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
				[_objectLoaderDelegate objectLoaderDidLoadUnexpectedResponse:self];
			}			
		}
	}
	
	if ([_objectLoaderDelegate respondsToSelector:@selector(requestDidFinishLoad:)]) {
		[(NSObject<RKRequestDelegate>*)_objectLoaderDelegate requestDidFinishLoad:request withResponse:response];
	}
}

- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error {
	if ([_objectLoaderDelegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
		[(NSObject<RKRequestDelegate>*)_objectLoaderDelegate request:request didFailLoadWithError:error];
	}
}

- (void)request:(RKRequest*)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	if ([_objectLoaderDelegate respondsToSelector:@selector(request:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
		[(NSObject<RKRequestDelegate>*)_objectLoaderDelegate request:request didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
	}
}

@end
