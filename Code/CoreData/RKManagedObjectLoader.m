//
//  RKManagedObjectLoader.m
//  RestKit
//
//  Created by Blake Watters on 2/13/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectLoader.h"
#import "RKURL.h"
#import "RKManagedObject.h"
#import "RKManagedObjectStore.h"

@interface RKObjectLoader (Private)

@property (nonatomic, readonly) RKManagedObjectStore* objectStore;
@property (nonatomic, readonly) RKObjectMapper* mapper;

- (void)informDelegateOfObjectLoadWithInfoDictionary:(NSDictionary*)dictionary;
@end

@implementation RKManagedObjectLoader

- (void)dealloc {
    [_targetObject release];
	_targetObject = nil;
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
}

- (RKManagedObjectStore*)objectStore {
    return [self.objectManager objectStore];
}

- (RKObjectMapper*)mapper {
    return [self.objectManager mapper];
}

- (void)informDelegateOfObjectLoadWithInfoDictionary:(NSDictionary*)dictionary {
    NSMutableDictionary* newInfo = [[NSMutableDictionary alloc] initWithDictionary:dictionary];
	NSArray* models = [dictionary objectForKey:@"objects"];
	[dictionary release];

	NSArray* objects = nil;
	RKManagedObjectStore* store = [RKObjectManager sharedManager].objectStore;
	NSArray* fetchRequests = [store.managedObjectCache fetchRequestsForResourcePath:self.resourcePath];
	if (store.managedObjectCache && fetchRequests) {
		objects = [RKManagedObject objectsWithFetchRequests:fetchRequests];

	} else {
		// NOTE: The models dictionary may contain NSManagedObjectID's from persistent objects
		// that were model mapped on a background thread. We look up the objects by ID and then
		// notify the delegate that the operation has completed.
		objects = [NSMutableArray arrayWithCapacity:[models count]];
		for (id object in models) {
			if ([object isKindOfClass:[NSManagedObjectID class]]) {
				id obj = [self.objectStore objectWithID:(NSManagedObjectID*)object];
				[(NSMutableArray*)objects addObject:obj];
			} else {
				[(NSMutableArray*)objects addObject:object];
			}
		}
	}

	[newInfo setObject:objects forKey:@"objects"];

	[super informDelegateOfObjectLoadWithInfoDictionary:newInfo];
}

- (void)processLoadModelsInBackground:(RKResponse*)response {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	NSArray* results = nil;
	NSError* error = nil;
	RKManagedObjectStore* store = [RKObjectManager sharedManager].objectStore;
	NSArray* fetchRequests = [store.managedObjectCache fetchRequestsForResourcePath:self.resourcePath];

	if (![response wasLoadedFromCache] || store == nil || fetchRequests == nil) {
		/**
		 * If this loader is bound to a particular object, then we map
		 * the results back into the instance. This is used for loading and updating
		 * individual object instances via getObject & friends.
		 */
		if (self.targetObject) {
			if (_targetObjectID) {
				NSManagedObject* backgroundThreadModel = [self.objectStore objectWithID:_targetObjectID];
				if (self.method == RKRequestMethodDELETE) {
					[[self.objectStore managedObjectContext] deleteObject:backgroundThreadModel];
				} else {
					[self.mapper mapObject:backgroundThreadModel fromString:[response bodyAsString]];
					results = [NSArray arrayWithObject:backgroundThreadModel];
				}
			} else {
				[self.mapper mapObject:self.targetObject fromString:[response bodyAsString]];
				results = [NSArray arrayWithObject:self.targetObject];
			}
		} else {
			id result = [self.mapper mapFromString:[response bodyAsString]
										   toClass:self.objectClass
										   keyPath:_keyPath];
			if ([result isKindOfClass:[NSArray class]]) {
				results = (NSArray*)result;
			} else {
				// Using arrayWithObjects: instead of arrayWithObject:
				// so that in the event result is nil, then we get empty array instead of
				// exception for trying to insert nil.
				results = [NSArray arrayWithObjects:result, nil];
			}

			if (self.objectStore && [self.objectStore managedObjectCache]) {
				if ([self.URL isKindOfClass:[RKURL class]]) {
					RKURL* rkURL = (RKURL*)self.URL;

					NSArray* fetchRequests = [[self.objectStore managedObjectCache]
											  fetchRequestsForResourcePath:rkURL.resourcePath];
					NSArray* cachedObjects = [RKManagedObject objectsWithFetchRequests:fetchRequests];
					for (id object in cachedObjects) {
						if ([object isKindOfClass:[RKManagedObject class]]) {
							if (NO == [results containsObject:object]) {
								[[self.objectStore managedObjectContext] deleteObject:object];
							}
						}
					}
				}
			}
		}

		// Before looking up NSManagedObjectIDs, need to save to ensure we do not have
		// temporary IDs for new objects prior to handing the objectIDs across threads
		error = [self.objectStore save];
	}

	if (nil != error) {
		NSDictionary* infoDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
										 response, @"response", error, @"error", nil] retain];
		[self performSelectorOnMainThread:@selector(informDelegateOfObjectLoadErrorWithInfoDictionary:)
							   withObject:infoDictionary waitUntilDone:YES];
	} else {
		// NOTE: Passing Core Data objects across threads is not safe.
		// Iterate over each model and coerce Core Data objects into ID's to pass across the threads.
		// The object ID's will be deserialized back into objects on the main thread
		// before the delegate is called back
		NSMutableArray* models = [NSMutableArray array];
		for (id object in results) {
			if ([object isKindOfClass:[NSManagedObject class]]) {
				[models addObject:[(NSManagedObject*)object objectID]];
			} else {
				[models addObject:object];
			}
		}

		NSDictionary* infoDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:
										 response, @"response", models, @"objects", nil] retain];
		[self performSelectorOnMainThread:@selector(informDelegateOfObjectLoadWithInfoDictionary:)
							   withObject:infoDictionary waitUntilDone:YES];
	}

	[pool drain];
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
			[self.objectStore save];
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
