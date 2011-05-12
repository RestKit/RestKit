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
#import "RKObjectMapper.h"

@interface RKObjectLoader (Private)

@property (nonatomic, readonly) RKManagedObjectStore* objectStore;

- (void)handleTargetObject;
- (void)informDelegateOfObjectLoadWithInfoDictionary:(NSDictionary*)dictionary;
@end

// TODO: I believe that we want to eliminate the subclass here and roll the managed object
// handling into another object that is set as the delegate on the object loader.
@implementation RKManagedObjectLoader

- (id)init {
    if ((self = [super init])) {
        _managedKeyPathsAndObjectIDs = [NSMutableDictionary new];
        _managedKeyPathsAndObjects = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [_targetObject release];
	_targetObject = nil;
	[_targetObjectID release];
	_targetObjectID = nil;
    [_managedKeyPathsAndObjectIDs release];
    [_managedKeyPathsAndObjects release];
    
    [super dealloc];
}

- (void)setTargetObject:(NSObject*)targetObject {
	[_targetObject release];
	_targetObject = nil;	
	_targetObject = [targetObject retain];	
    
	[_targetObjectID release];
	_targetObjectID = nil;
}

- (void)informDelegateOfObjectLoadWithInfoDictionary:(NSDictionary*)dictionary {
    RKObjectMappingResult* result = [dictionary objectForKey:@"result"];
	[dictionary release];
    
    
    // Swap out any objects in the results with their managed object coutnerparts on this thread based on
    // they keys and ids in _managedKeyPathsAndObjectIDs
    
    NSMutableDictionary* resultsDictionary = [[[result asDictionary] mutableCopy] autorelease];
    for (NSString* keyPath in [_managedKeyPathsAndObjectIDs allKeys]) {
        id objectIDorIDs = [_managedKeyPathsAndObjectIDs objectForKey:keyPath];
        if ([objectIDorIDs isKindOfClass:[NSManagedObjectID class]]) {
            NSManagedObject* object = [self.objectStore objectWithID:(NSManagedObjectID*)objectIDorIDs];
            [resultsDictionary setValue:object forKey:keyPath];
        } else if ([objectIDorIDs isKindOfClass:[NSArray class]]) {
            NSMutableArray* array = [NSMutableArray array];
            for (NSManagedObjectID* objectID in (NSArray*)objectIDorIDs) {
                NSManagedObject* object = [self.objectStore objectWithID:objectID];
                [array addObject:object];
            }
            [resultsDictionary setValue:array forKey:keyPath];
        }
            
    }
    
    result = [RKObjectMappingResult mappingResultWithDictionary:resultsDictionary];
    
    if ([self.delegate respondsToSelector:@selector(objectLoader:didLoadObjects:)]) {
        [(NSObject<RKObjectLoaderDelegate>*)self.delegate objectLoader:self didLoadObjects:[result asCollection]];
    } else if ([self.delegate respondsToSelector:@selector(objectLoader:didLoadObject:)]) {
        [(NSObject<RKObjectLoaderDelegate>*)self.delegate objectLoader:self didLoadObject:[result asObject]];
    } else if ([self.delegate respondsToSelector:@selector(objectLoader:didLoadObjectDictionary:)]) {
        [(NSObject<RKObjectLoaderDelegate>*)self.delegate objectLoader:self didLoadObjectDictionary:[result asDictionary]];
    }
    
	[self responseProcessingSuccessful:YES withError:nil];
}

- (void)objectMapper:(RKObjectMapper*)objectMapper didMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)objectMapping {
    
    Class managedObjectClass = NSClassFromString(@"NSManagedObject");
    if (self.objectStore && managedObjectClass) {
        if ([destinationObject isKindOfClass:managedObjectClass]) {
            id objectIDorIDsForKeyPath = [_managedKeyPathsAndObjects objectForKey:keyPath];
            if (nil == objectIDorIDsForKeyPath) {
                [_managedKeyPathsAndObjects setValue:destinationObject forKey:keyPath];
            } else if ([objectIDorIDsForKeyPath isKindOfClass:[NSManagedObject class]]) {
                NSMutableArray* array = [NSMutableArray arrayWithObject:destinationObject];
                [array addObject:destinationObject];
                [_managedKeyPathsAndObjects setValue:array forKey:keyPath];
            } else {
                NSMutableArray* array = (NSMutableArray*)objectIDorIDsForKeyPath;
                [array addObject:destinationObject];
            }
        }
    }
}

- (void)getPermanantObjectIdsForManagedObjects {
    for (NSString* keyPath in [_managedKeyPathsAndObjects allKeys]) {
        id objectOrObjects = [_managedKeyPathsAndObjects objectForKey:keyPath];
        if ([objectOrObjects isKindOfClass:[NSManagedObject class]]) {
            NSManagedObjectID* objectID = [(NSManagedObject*)objectOrObjects objectID];
            [_managedKeyPathsAndObjectIDs setValue:objectID forKey:keyPath];
        } else if ([objectOrObjects isKindOfClass:[NSArray class]]) {
            NSMutableArray* array = [NSMutableArray array];
            for (NSManagedObject* object in (NSArray*)objectOrObjects) {
                NSManagedObjectID* objectID = [(NSManagedObject*)object objectID];
                [array addObject:objectID];
            }
            [_managedKeyPathsAndObjectIDs setValue:array forKey:keyPath];
        }
        [_managedKeyPathsAndObjects removeObjectForKey:keyPath];
    }
}

- (void)processLoadModelsInBackground:(RKResponse *)response {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    RKObjectMappingProvider* mappingProvider;
    if (self.objectMapping) {
        mappingProvider = [[RKObjectMappingProvider new] autorelease];
        [mappingProvider setMapping:self.objectMapping forKeyPath:@""];
    } else {
        mappingProvider = self.objectManager.mappingProvider;
    }
    
    RKObjectMappingResult* result = nil;
    if (_targetObjectID && self.targetObject && self.method == RKRequestMethodDELETE) {
        NSManagedObject* backgroundThreadModel = [self.objectStore objectWithID:_targetObjectID];
        [[self.objectStore managedObjectContext] deleteObject:backgroundThreadModel];
    } else {
        result = [self mapResponse:response withMappingProvider:mappingProvider];
    }
    
    [self.objectStore save];
    [self getPermanantObjectIdsForManagedObjects];
    
    NSDictionary* infoDictionary = [[NSDictionary dictionaryWithObjectsAndKeys:response, @"response", result, @"result", nil] retain];
    [self performSelectorOnMainThread:@selector(informDelegateOfObjectLoadWithInfoDictionary:) withObject:infoDictionary waitUntilDone:YES];
    
	[pool drain];
}

// Give the target object a chance to modify the request. This is invoked during prepareURLRequest right before it hits the wire
- (void)handleTargetObject {
	if (self.targetObject) {
		if ([self.targetObject isKindOfClass:[NSManagedObject class]]) {
			// NOTE: There is an important sequencing issue here. You MUST save the
			// managed object context before retaining the objectID or you will run
			// into an error where the object context cannot be saved. We do this
			// right before send to avoid sequencing issues where the target object is
			// set before the managed object store.
            // TODO: Can we just obtain a permanent object ID instead of saving the store???
			[self.objectStore save];
			_targetObjectID = [[(NSManagedObject*)self.targetObject objectID] retain];
		}
		
		[super handleTargetObject];
	}
}

- (RKManagedObjectStore*)objectStore {
    return self.objectManager.objectStore;
}

@end
