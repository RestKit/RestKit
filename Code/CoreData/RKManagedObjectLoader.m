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
#import "RKManagedObjectFactory.h"
#import "RKManagedObjectThreadSafeInvocation.h"

// TODO: Move me to a new header file for sharing...
@interface RKObjectLoader (Private)

@property (nonatomic, readonly) RKManagedObjectStore* objectStore;

- (void)handleTargetObject;
- (void)informDelegateOfObjectLoadWithInfoDictionary:(NSDictionary*)dictionary;
- (void)performMappingOnBackgroundThread;
@end

@implementation RKManagedObjectLoader

- (id)init {
    self = [super init];
    if (self) {
        _managedObjectKeyPaths = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)dealloc {
	[_targetObjectID release];
	_targetObjectID = nil;
    [_managedObjectKeyPaths release];
    
    [super dealloc];
}

- (void)objectMapper:(RKObjectMapper*)objectMapper didMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)objectMapping {
    Class managedObjectClass = NSClassFromString(@"NSManagedObject");
    if (self.objectStore && managedObjectClass) {
        if ([destinationObject isKindOfClass:managedObjectClass]) {
            // TODO: logging here
            [_managedObjectKeyPaths addObject:keyPath];
        }
    }
}

- (RKManagedObjectStore*)objectStore {
    return self.objectManager.objectStore;
}

#pragma mark - Subclass Hooks

- (void)performMappingOnBackgroundThread {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    // Refetch the target object now that we are on the background thread
    if (_targetObjectID) {
        self.targetObject = [self.objectStore objectWithID:_targetObjectID];
    }
    
    // Let RKObjectLoader handle the processing...
    [super performMappingOnBackgroundThread];    
    [pool drain];
}

- (void)setTargetObject:(NSObject*)targetObject {
	[_targetObject release];
	_targetObject = nil;	
	_targetObject = [targetObject retain];	
    
	[_targetObjectID release];
	_targetObjectID = nil;
    
    // Obtain a permanent ID for the object
    // NOTE: There is an important sequencing issue here. You MUST save the
    // managed object context before retaining the objectID or you will run
    // into an error where the object context cannot be saved. We do this
    // right before send to avoid sequencing issues where the target object is
    // set before the managed object store.
    // TODO: Can we just obtain a permanent object ID instead of saving the store???
    if ([targetObject isKindOfClass:[NSManagedObject class]]) {
        NSManagedObjectContext* context = self.objectStore.managedObjectContext;
        NSError* error = nil;
        if ([context obtainPermanentIDsForObjects:[NSArray arrayWithObject:targetObject] error:&error]) {
            _targetObjectID = [[(NSManagedObject*)targetObject objectID] retain];
        }
    }
}

- (void)processMappingResult:(RKObjectMappingResult*)result {
    // TODO: Need tests around the deletion case
    // TODO: Save the store... handle deletion...
    //    RKObjectMappingResult* result = nil;
    //    if (_targetObjectID && self.targetObject && self.method == RKRequestMethodDELETE) {
    //        NSManagedObject* backgroundThreadModel = [self.objectStore objectWithID:_targetObjectID];
    //        [[self.objectStore managedObjectContext] deleteObject:backgroundThreadModel];
    //    } else {
    //        result = [self mapResponse:response withMappingProvider:mappingProvider];
    //    }
    
    // If the response was successful, save the store...
    [self.objectStore save];
    
    NSDictionary* dictionary = [result asDictionary];
    NSMethodSignature* signature = [self methodSignatureForSelector:@selector(informDelegateOfObjectLoadWithResultDictionary:)];
    RKManagedObjectThreadSafeInvocation* invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    [invocation setObjectStore:self.objectStore];
    [invocation setTarget:self];
    [invocation setSelector:@selector(informDelegateOfObjectLoadWithResultDictionary:)];
    [invocation setArgument:&dictionary atIndex:2];
    [invocation setManagedObjectKeyPaths:_managedObjectKeyPaths forArgument:2];
    [invocation invokeOnMainThread];
}

- (id<RKObjectFactory>)createObjectFactory {
    if (self.objectManager.objectStore) {
        return [RKManagedObjectFactory objectFactoryWithObjectStore:self.objectStore];
    }
    
    return nil;    
}

@end
