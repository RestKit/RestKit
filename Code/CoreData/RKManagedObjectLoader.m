//
//  RKManagedObjectLoader.m
//  RestKit
//
//  Created by Blake Watters on 2/13/11.
//  Copyright 2011 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKObjectManager.h"
#import "RKManagedObjectLoader.h"
#import "RKURL.h"
#import "RKObjectMapper.h"
#import "RKManagedObjectThreadSafeInvocation.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKObjectLoader_Internals.h"
#import "RKRequest_Internals.h"
#import "RKLog.h"

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
    _deleteObjectOnFailure = NO;
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

- (BOOL)prepareURLRequest {
    // TODO: Can we just do this if the object hasn't been saved already???
    
    // NOTE: There is an important sequencing issue here. You MUST save the
    // managed object context before retaining the objectID or you will run
    // into an error where the object context cannot be saved. We do this
    // right before send to avoid sequencing issues where the target object is
    // set before the managed object store.
    if (self.targetObject && [self.targetObject isKindOfClass:[NSManagedObject class]]) {
        _deleteObjectOnFailure = [(NSManagedObject*)self.targetObject isNew];
        [self.objectStore save];
        _targetObjectID = [[(NSManagedObject*)self.targetObject objectID] retain];
    }
    
    return [super prepareURLRequest];
}

- (void)deleteCachedObjectsMissingFromResult:(RKObjectMappingResult*)result {
    if (! [self isGET]) {
        RKLogDebug(@"Skipping cleanup of objects via managed object cache: only used for GET requests.");
        return;
    }
    
    if ([self.URL isKindOfClass:[RKURL class]]) {
        RKURL* rkURL = (RKURL*)self.URL;
        
        NSArray* results = [result asCollection];
        NSArray* cachedObjects = [self.objectStore objectsForResourcePath:rkURL.resourcePath];
        NSObject<RKManagedObjectCache>* managedObjectCache = self.objectStore.managedObjectCache;
        BOOL queryForDeletion = [managedObjectCache respondsToSelector:@selector(shouldDeleteOrphanedObject:)];
      
        for (id object in cachedObjects) {
            if (NO == [results containsObject:object]) {
              if (queryForDeletion && [managedObjectCache shouldDeleteOrphanedObject:object] == NO)
              {
                RKLogTrace(@"Sparing orphaned object %@ even though not returned in result set", object);
              }
              else
              {
                RKLogTrace(@"Deleting orphaned object %@: not found in result set and expected at this resource path", object);
                [[self.objectStore managedObjectContext] deleteObject:object];
              }
            }
        }
    } else {
        RKLogWarning(@"Unable to perform cleanup of server-side object deletions: unable to determine resource path.");
    } 
}

// NOTE: We are on the background thread here, be mindful of Core Data's threading needs
- (void)processMappingResult:(RKObjectMappingResult*)result {
    NSAssert(_sentSynchronously || ![NSThread isMainThread], @"Mapping result processing should occur on a background thread");
    if (_targetObjectID && self.targetObject && self.method == RKRequestMethodDELETE) {
        NSManagedObject* backgroundThreadObject = [self.objectStore objectWithID:_targetObjectID];
        RKLogInfo(@"Deleting local object %@ due to DELETE request", backgroundThreadObject);
        [[self.objectStore managedObjectContext] deleteObject:backgroundThreadObject];        
    }
    
    // If the response was successful, save the store...
    if ([self.response isSuccessful]) {
        [self deleteCachedObjectsMissingFromResult:result];
        NSError* error = [self.objectStore save];
        if (error) {
            RKLogError(@"Failed to save managed object context after mapping completed: %@", [error localizedDescription]);
            NSMethodSignature* signature = [self.delegate methodSignatureForSelector:@selector(objectLoader:didFailWithError:)];
            RKManagedObjectThreadSafeInvocation* invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:self.delegate];
            [invocation setSelector:@selector(objectLoader:didFailWithError:)];
            [invocation setArgument:&self atIndex:2];
            [invocation setArgument:&error atIndex:3];
            [invocation invokeOnMainThread];
            return;
        }
    }
    
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

// Overloaded to handle deleting an object orphaned by a failed postObject:
- (void)handleResponseError {
    [super handleResponseError];
    
    if (_targetObjectID) {
        if (_deleteObjectOnFailure) {
            RKLogInfo(@"Error response encountered: Deleting existing managed object with ID: %@", _targetObjectID);
            NSManagedObject* objectToDelete = [self.objectStore objectWithID:_targetObjectID];
            if (objectToDelete) {
                [[self.objectStore managedObjectContext] deleteObject:objectToDelete];
                [self.objectStore save];
            } else {
                RKLogWarning(@"Unable to delete existing managed object with ID: %@. Object not found in the store.", _targetObjectID);
            }
        } else {
            RKLogDebug(@"Skipping deletion of existing managed object");
        }
    }
}

@end
