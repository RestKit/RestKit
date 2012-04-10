//
//  RKManagedObjectLoader.m
//  RestKit
//
//  Created by Blake Watters on 2/13/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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
#import "RKObjectMappingProvider+CoreData.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@implementation RKManagedObjectLoader

@synthesize objectStore = _objectStore;

+ (id)loaderWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider objectStore:(RKManagedObjectStore *)objectStore {
    return [[[self alloc] initWithURL:URL mappingProvider:mappingProvider objectStore:objectStore] autorelease];
}

- (id)initWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider objectStore:(RKManagedObjectStore *)objectStore {
    self = [self initWithURL:URL mappingProvider:mappingProvider];
    if (self) {
        _objectStore = [objectStore retain];
    }
    
    return self;
}

- (id)initWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider {
    self = [super initWithURL:URL mappingProvider:mappingProvider];
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
    [_objectStore release];
    
    [super dealloc];
}

- (void)reset {
    [super reset]; 
    [_targetObjectID release];
    _targetObjectID = nil;
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
        [self.objectStore save:nil];
        _targetObjectID = [[(NSManagedObject*)self.targetObject objectID] retain];
    }
    
    return [super prepareURLRequest];
}

- (NSArray *)cachedObjects {
    NSFetchRequest *fetchRequest = [self.mappingProvider fetchRequestForResourcePath:self.resourcePath];
    if (fetchRequest) {
        return [NSManagedObject objectsWithFetchRequest:fetchRequest];
    }
    
    return nil;
}

- (void)deleteCachedObjectsMissingFromResult:(RKObjectMappingResult*)result {
    if (! [self isGET]) {
        RKLogDebug(@"Skipping cleanup of objects via managed object cache: only used for GET requests.");
        return;
    }
    
    if ([self.URL isKindOfClass:[RKURL class]]) {
        NSArray *results = [result asCollection];
        NSArray *cachedObjects = [self cachedObjects];
        for (id object in cachedObjects) {
            if (NO == [results containsObject:object]) {
                RKLogTrace(@"Deleting orphaned object %@: not found in result set and expected at this resource path", object);
                [[self.objectStore managedObjectContextForCurrentThread] deleteObject:object];
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
        [[self.objectStore managedObjectContextForCurrentThread] deleteObject:backgroundThreadObject];        
    }
    
    // If the response was successful, save the store...
    if ([self.response isSuccessful]) {
        [self deleteCachedObjectsMissingFromResult:result];
        NSError *error = nil;
        BOOL success = [self.objectStore save:&error];
        if (! success) {
            RKLogError(@"Failed to save managed object context after mapping completed: %@", [error localizedDescription]);
            NSMethodSignature* signature = [(NSObject *)self methodSignatureForSelector:@selector(informDelegateOfError:)];
            RKManagedObjectThreadSafeInvocation* invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:self];
            [invocation setSelector:@selector(informDelegateOfError:)];
            [invocation setArgument:&error atIndex:2];
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
                [[self.objectStore managedObjectContextForCurrentThread] deleteObject:objectToDelete];
                [self.objectStore save:nil];
            } else {
                RKLogWarning(@"Unable to delete existing managed object with ID: %@. Object not found in the store.", _targetObjectID);
            }
        } else {
            RKLogDebug(@"Skipping deletion of existing managed object");
        }
    }
}

- (BOOL)isResponseMappable {
    if ([self.response wasLoadedFromCache]) {
        NSArray* cachedObjects = [self cachedObjects];
        if (! cachedObjects) {
            RKLogDebug(@"Skipping managed object mapping optimization -> Managed object cache returned nil cachedObjects for resourcePath: %@", self.resourcePath);
            return [super isResponseMappable];
        }
        [self informDelegateOfObjectLoadWithResultDictionary:[NSDictionary dictionaryWithObject:cachedObjects forKey:@""]];
        return NO;
    }
    return [super isResponseMappable];
}

@end
