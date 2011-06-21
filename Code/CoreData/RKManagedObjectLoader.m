//
//  RKManagedObjectLoader.m
//  RestKit
//
//  Created by Blake Watters on 2/13/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectManager.h"
#import "RKManagedObjectLoader.h"
#import "RKURL.h"
#import "RKObjectMapper.h"
#import "RKManagedObjectFactory.h"
#import "RKManagedObjectThreadSafeInvocation.h"
#import "../ObjectMapping/RKObjectLoader_Internals.h"
#import "../Network/RKRequest_Internals.h"

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

- (void)reset {
    [super reset]; 
    [_targetObjectID release];
    _targetObjectID = nil;
}

- (RKManagedObjectStore*)objectStore {
    return self.objectManager.objectStore;
}

#pragma mark - RKObjectMapperDelegate methods

- (void)objectMapper:(RKObjectMapper*)objectMapper didMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString*)keyPath usingMapping:(RKObjectMapping*)objectMapping {
    if ([destinationObject isKindOfClass:[NSManagedObject class]]) {
        [_managedObjectKeyPaths addObject:keyPath];
    }
}

#pragma mark - RKObjectLoader overrides

// Overload the target object reader to return a thread-local copy of the target object
- (id)targetObject {
    if ([NSThread isMainThread] == NO && _targetObjectID) {
        return [self.objectStore objectWithID:_targetObjectID];        
    }
    
    return _targetObject;
}

- (void)setTargetObject:(NSObject*)targetObject {
    [_targetObject release];
    _targetObject = nil;	
    _targetObject = [targetObject retain];	

    [_targetObjectID release];
    _targetObjectID = nil;
}

- (void)prepareURLRequest {
    // TODO: Can we just do this if the object hasn't been saved already???
    
    // NOTE: There is an important sequencing issue here. You MUST save the
    // managed object context before retaining the objectID or you will run
    // into an error where the object context cannot be saved. We do this
    // right before send to avoid sequencing issues where the target object is
    // set before the managed object store.
    if (self.targetObject && [self.targetObject isKindOfClass:[NSManagedObject class]]) {
        [self.objectStore save];
        _targetObjectID = [[(NSManagedObject*)self.targetObject objectID] retain];
    }
    
    [super prepareURLRequest];
}

// NOTE: We are on the background thread here, be mindful of Core Data's threading needs
- (void)processMappingResult:(RKObjectMappingResult*)result {
    if (_targetObjectID && self.targetObject && self.method == RKRequestMethodDELETE) {
        // TODO: Logging
        NSManagedObject* backgroundThreadObject = [self.objectStore objectWithID:_targetObjectID];
        [[self.objectStore managedObjectContext] deleteObject:backgroundThreadObject];
    }
    
    // If the response was successful, save the store...
    if ([self.response isSuccessful]) {
        // TODO: Logging or delegate notifications?
        [self.objectStore save];
    }
    
    // TODO: If unsuccessful and we saved the object, remove it from the store so that it is not orphaned
    
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

// Overloaded to handle deleting an object orphaned by a failed postObject:
- (void)handleResponseError {
    [super handleResponseError];
    
    if (_targetObjectID) {
        RKLogInfo(@"Error response encountered: Deleting existing managed object with ID: %@", _targetObjectID);
        NSManagedObject* objectToDelete = [self.objectStore objectWithID:_targetObjectID];
        if (objectToDelete) {
            [[self.objectStore managedObjectContext] deleteObject:objectToDelete];
            [self.objectStore save];
        } else {
            RKLogWarning(@"Unable to delete existing managed object with ID: %@. Object not found in the store.", _targetObjectID);
        }
    }
}

@end
