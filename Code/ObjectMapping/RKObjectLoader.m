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
#import "RKNotifications.h"
#import <UIKit/UIKit.h>

@implementation RKObjectLoader

@synthesize mapper = _mapper, response = _response, objectClass = _objectClass, targetObject = _targetObject,
			keyPath = _keyPath, managedObjectStore = _managedObjectStore;

+ (id)loaderWithResourcePath:(NSString*)resourcePath mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	return [self loaderWithResourcePath:resourcePath client:[RKClient sharedClient] mapper:mapper delegate:delegate];
}

+ (id)loaderWithResourcePath:(NSString*)resourcePath client:(RKClient*)client mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	return [[[self alloc] initWithResourcePath:resourcePath client:client mapper:mapper delegate:delegate] autorelease];
}

- (id)initWithResourcePath:(NSString*)resourcePath mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	return [self initWithResourcePath:resourcePath client:[RKClient sharedClient] mapper:mapper delegate:delegate];
}

- (id)initWithResourcePath:(NSString*)resourcePath client:(RKClient*)client mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	if ((self = [self initWithURL:[client URLForResourcePath:resourcePath] delegate:delegate])) {
		_mapper = [mapper retain];
		self.managedObjectStore = nil;
		_targetObjectID = nil;
		_client = [client retain];
		[_client setupRequest:self];
	}
	return self;
}

- (void)dealloc {
	[_mapper release];
	_mapper = nil;
	[_response release];
	_response = nil;
	[_keyPath release];
	_keyPath = nil;
	[_targetObject release];
	_targetObject = nil;
	[_targetObjectID release];
	_targetObjectID = nil;
	[_client release];
	_client = nil;
	self.managedObjectStore = nil;
	[super dealloc];
}

- (void)setTargetObject:(NSObject<RKObjectMappable>*)targetObject {
	[_targetObject release];
	_targetObject = nil;	
	_targetObject = [targetObject retain];	

	[_targetObjectID release];
	_targetObjectID = nil;
}


#pragma mark Response Processing

- (void)responseProcessingSuccessful:(BOOL)successful withError:(NSError*)error {
	_isLoading = NO;

	NSDate* receivedAt = [NSDate date];
	if (successful) {
		_isLoaded = YES;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod",
								  [self URL], @"URL",
								  receivedAt, @"receivedAt",
								  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kRKResponseReceivedNotification
															object:_response
														  userInfo:userInfo];
	} else {
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod",
								  [self URL], @"URL",
								  receivedAt, @"receivedAt",
								  error, @"error",
								  nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kRKRequestFailedWithErrorNotification
															object:self
														  userInfo:userInfo];
	}
}

- (BOOL)encounteredErrorWhileProcessingRequest:(RKResponse*)response {
	if ([response isFailure]) {
		[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:response.failureError];

		[self responseProcessingSuccessful:NO withError:response.failureError];

		return YES;
	} else if ([response isError]) {
		NSError* error = nil;

		if ([response isJSON]) {
			error = [_mapper parseErrorFromString:[response bodyAsString]];
			[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];

		} else if ([response isServiceUnavailable] && [_client serviceUnavailableAlertEnabled]) {
			if ([_delegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
				[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoaderDidLoadUnexpectedResponse:self];
			}

			UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[_client serviceUnavailableAlertTitle]
																message:[_client serviceUnavailableAlertMessage]
															   delegate:nil
													  cancelButtonTitle:NSLocalizedString(@"OK", nil)
													  otherButtonTitles:nil];
			[alertView show];
			[alertView release];

		} else {
			// TODO: We've likely run into a maintenance page here.  Consider adding the ability
			// to put the stack into offline mode in response...
			if ([_delegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
				[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoaderDidLoadUnexpectedResponse:self];
			}
		}

		[self responseProcessingSuccessful:NO withError:error];

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
			id obj = [self.managedObjectStore objectWithID:(NSManagedObjectID*)object];
			NSLog(@"OBJ: %@", obj);
			[objects addObject:obj];
		} else {
			[objects addObject:object];
		}
	}

	[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didLoadObjects:[NSArray arrayWithArray:objects]];

	[self responseProcessingSuccessful:YES withError:nil];
}

- (void)informDelegateOfObjectLoadErrorWithInfoDictionary:(NSDictionary*)dictionary {
	NSError* error = [dictionary objectForKey:@"error"];
	[dictionary release];

	NSLog(@"[RestKit] RKObjectLoader: Error saving managed object context: error=%@ userInfo=%@", error, error.userInfo);

	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  [error localizedDescription], NSLocalizedDescriptionKey,
							  nil];
	NSError *rkError = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectLoaderRemoteSystemError userInfo:userInfo];

	[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:rkError];

	[self responseProcessingSuccessful:NO withError:rkError];
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
			if (self.method == RKRequestMethodDELETE) {
				[[objectStore managedObjectContext] deleteObject:backgroundThreadModel];
			} else {
				[_mapper mapObject:backgroundThreadModel fromString:[response bodyAsString]];
				results = [NSArray arrayWithObject:backgroundThreadModel];
			}
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
		[self performSelectorOnMainThread:@selector(informDelegateOfObjectLoadErrorWithInfoDictionary:) withObject:infoDictionary waitUntilDone:YES];
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
		[self performSelectorOnMainThread:@selector(informDelegateOfObjectLoadWithInfoDictionary:) withObject:infoDictionary waitUntilDone:YES];
	}

	[pool drain];
}

- (void)didFailLoadWithError:(NSError*)error {
	if ([_delegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
		[_delegate request:self didFailLoadWithError:error];
	}

	[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoader:self didFailWithError:error];

	[self responseProcessingSuccessful:NO withError:error];
}

- (void)didFinishLoad:(RKResponse*)response {
	_response = [response retain];

	if ([_delegate respondsToSelector:@selector(request:didLoadResponse:)]) {
		[_delegate request:self didLoadResponse:response];
	}

	if (NO == [self encounteredErrorWhileProcessingRequest:response]) {
		// TODO: When other mapping formats are supported, unwind this assumption... Should probably be an expected MIME types array set by client/manager
		if ([response isSuccessful] && [response isJSON]) {
			[self performSelectorInBackground:@selector(processLoadModelsInBackground:) withObject:response];
		} else {
			NSLog(@"Encountered unexpected response code: %d (MIME Type: %@)", response.statusCode, response.MIMEType);
			if ([_delegate respondsToSelector:@selector(objectLoaderDidLoadUnexpectedResponse:)]) {
				[(NSObject<RKObjectLoaderDelegate>*)_delegate objectLoaderDidLoadUnexpectedResponse:self];
			}
			[self responseProcessingSuccessful:NO withError:nil];
		}
	}
}

// Give the target object a chance to modify the request
- (void)handleTargetObject {
	if (self.targetObject) {
		if ([self.targetObject isKindOfClass:[NSManagedObject class]]) {
			// NOTE: There is an important sequencing issue here. You MUST save the
			// managed object context before retaining the objectID or you will run
			// into an error where the object context cannot be saved. We do this
			// right before send to avoid sequencing issues where the target object is
			// set before the managed object store.
			[self.managedObjectStore save];
			_targetObjectID = [[(NSManagedObject*)self.targetObject objectID] retain];
		}
		
		if ([self.targetObject respondsToSelector:@selector(willSendWithObjectLoader:)]) {
			[self.targetObject willSendWithObjectLoader:self];
		}
	}
}

- (void)send {
	[self handleTargetObject];
	[super send];
}

- (RKResponse*)sendSynchronously {
	[self handleTargetObject];
	return [super sendSynchronously];
}

@end
