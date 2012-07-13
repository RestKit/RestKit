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
#import "RKManagedObjectMappingOperationDataSource.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@interface RKManagedObjectLoader ()

@property (nonatomic, retain) NSManagedObjectID *targetObjectID;
@property (nonatomic, retain) NSMutableSet *managedObjectKeyPaths;
@property (nonatomic, assign) BOOL deleteObjectOnFailure;
@property (nonatomic, retain, readwrite) NSManagedObjectContext *managedObjectContext;
@end

@implementation RKManagedObjectLoader

@synthesize objectStore = _objectStore;
@synthesize targetObjectID = _targetObjectID;
@synthesize managedObjectKeyPaths = _managedObjectKeyPaths;
@synthesize deleteObjectOnFailure = _deleteObjectOnFailure;

+ (id)loaderWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider objectStore:(RKManagedObjectStore *)objectStore
{
    return [[[self alloc] initWithURL:URL mappingProvider:mappingProvider objectStore:objectStore] autorelease];
}

- (id)initWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider objectStore:(RKManagedObjectStore *)objectStore
{
    self = [self initWithURL:URL mappingProvider:mappingProvider];
    if (self) {
        self.objectStore = objectStore;        
    }

    return self;
}

- (id)initWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider
{
    self = [super initWithURL:URL mappingProvider:mappingProvider];
    if (self) {
        self.managedObjectKeyPaths = [NSMutableSet set];
        [self addObserver:self forKeyPath:@"objectStore" options:0 context:nil];
    }

    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"objectStore"];
    self.targetObjectID = nil;
    self.managedObjectKeyPaths = nil;
    self.objectStore = nil;
    self.managedObjectContext = nil;

    [super dealloc];
}

- (void)reset
{
    [super reset];
    self.targetObjectID = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"objectStore"]) {
        self.managedObjectContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] autorelease];
        self.managedObjectContext.parentContext = self.objectStore.primaryManagedObjectContext;
        self.managedObjectContext.mergePolicy  = NSMergeByPropertyStoreTrumpMergePolicy;
        self.mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:self.managedObjectContext];
    }
}

#pragma mark - RKObjectMapperDelegate methods

- (void)objectMapper:(RKObjectMapper *)objectMapper didMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString *)keyPath usingMapping:(RKObjectMapping *)objectMapping
{
    if ([destinationObject isKindOfClass:[NSManagedObject class]]) {
        [_managedObjectKeyPaths addObject:keyPath];
    }
}

// TODO: This is a hack until we can figure out more elegant solution...
//- (void)objectMapper:(RKObjectMapper *)objectMapper willPerformMappingOperation:(RKObjectMappingOperation *)mappingOperation
//{
//    if ([mappingOperation isKindOfClass:[RKManagedObjectMappingOperation class]]) {
//        [(RKManagedObjectMappingOperation *)mappingOperation setManagedObjectContext:self.managedObjectContext];
//    }
//}

#pragma mark - RKObjectLoader overrides

// Overload the target object reader to return a thread-local copy of the target object
- (id)targetObject
{
    if ([NSThread isMainThread] == NO && _targetObjectID) {
        return [self.objectStore objectWithID:_targetObjectID];
    }

    return _targetObject;
}

- (void)setTargetObject:(id<NSObject>)targetObject
{
    [_targetObject release];
    _targetObject = nil;
    _targetObject = [targetObject retain];

    [_targetObjectID release];
    _targetObjectID = nil;
}

- (BOOL)prepareURLRequest
{
    // NOTE: There is an important sequencing issue here. You MUST save the
    // managed object context before retaining the objectID or you will run
    // into an error where the object context cannot be saved. We do this
    // right before send to avoid sequencing issues where the target object is
    // set before the managed object store.
    if (self.targetObject && [self.targetObject isKindOfClass:[NSManagedObject class]]) {
        self.deleteObjectOnFailure = [(NSManagedObject *)self.targetObject isNew];
        [self.objectStore save:nil];
        self.targetObjectID = [[(NSManagedObject *)self.targetObject objectID] retain];
    }

    return [super prepareURLRequest];
}

- (NSArray *)cachedObjects
{
    NSFetchRequest *fetchRequest = [self.mappingProvider fetchRequestForResourcePath:self.resourcePath];
    if (fetchRequest) {
        return [NSManagedObject objectsWithFetchRequest:fetchRequest];
    }

    return nil;
}

- (void)deleteCachedObjectsMissingFromResult:(RKObjectMappingResult *)result
{
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
- (void)processMappingResult:(RKObjectMappingResult *)result
{
    NSAssert(_sentSynchronously || ![NSThread isMainThread], @"Mapping result processing should occur on a background thread");
    if (_targetObjectID && self.targetObject && self.method == RKRequestMethodDELETE) {
        NSManagedObject *backgroundThreadObject = [self.objectStore objectWithID:_targetObjectID];
        RKLogInfo(@"Deleting local object %@ due to DELETE request", backgroundThreadObject);
        [[self.objectStore managedObjectContextForCurrentThread] deleteObject:backgroundThreadObject];
    }

    // If the response was successful, save the store...
    if ([self.response isSuccessful]) {
        [self deleteCachedObjectsMissingFromResult:result];
        __block BOOL success = NO;
        __block NSError *error = nil;
        
        NSLog(@"Before save...");
//        NSLog(@"Saving objectStore = %@. MOC = %@", self.objectStore, self.objectStore.managedObjectContextForCurrentThread);
        NSLog(@"Saving managedObjectContext: %@", self.managedObjectContext);
        
        [self.managedObjectContext performBlockAndWait:^{
            success = [self.managedObjectContext save:&error];
            NSLog(@"Saved MOC success = %d. Error: %@", success, error);
        }];
//        BOOL success = [self.objectStore save:&error];
        NSLog(@"After save...");
        if (! success) {
            RKLogError(@"Failed to save managed object context after mapping completed: %@", [error localizedDescription]);
            NSMethodSignature *signature = [(NSObject *)self methodSignatureForSelector:@selector(informDelegateOfError:)];
            RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:self];
            [invocation setSelector:@selector(informDelegateOfError:)];
            [invocation setArgument:&error atIndex:2];
            [invocation invokeOnMainThread];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self finalizeLoad:success];
            });
            return;
        }
    }

    NSDictionary *dictionary = [result asDictionary];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateOfObjectLoadWithResultDictionary:)];
    if (self.managedObjectContext.parentContext) {
        NSLog(@"Saving parent context...");
        [self.managedObjectContext.parentContext performBlockAndWait:^{
            NSError *error = nil;
            if (! [self.managedObjectContext.parentContext save:&error]) {
                NSLog(@"Failed to save parent context. Error: %@", error);
                
                if ([[error domain] isEqualToString:@"NSCocoaErrorDomain"]) {
                    NSDictionary *userInfo = [error userInfo];
                    NSArray *errors = [userInfo valueForKey:@"NSDetailedErrors"];
                    if (errors) {
                        for (NSError *detailedError in errors) {
                            NSDictionary *subUserInfo = [detailedError userInfo];
                            RKLogError(@"Core Data Save Error\n \
                                       NSLocalizedDescription:\t\t%@\n \
                                       NSValidationErrorKey:\t\t\t%@\n \
                                       NSValidationErrorPredicate:\t%@\n \
                                       NSValidationErrorObject:\n%@\n",
                                       [subUserInfo valueForKey:@"NSLocalizedDescription"],
                                       [subUserInfo valueForKey:@"NSValidationErrorKey"],
                                       [subUserInfo valueForKey:@"NSValidationErrorPredicate"],
                                       [subUserInfo valueForKey:@"NSValidationErrorObject"]);
                        }
                    }
                    else {
                        RKLogError(@"Core Data Save Error\n \
                                   NSLocalizedDescription:\t\t%@\n \
                                   NSValidationErrorKey:\t\t\t%@\n \
                                   NSValidationErrorPredicate:\t%@\n \
                                   NSValidationErrorObject:\n%@\n",
                                   [userInfo valueForKey:@"NSLocalizedDescription"],
                                   [userInfo valueForKey:@"NSValidationErrorKey"],
                                   [userInfo valueForKey:@"NSValidationErrorPredicate"],
                                   [userInfo valueForKey:@"NSValidationErrorObject"]);
                    }
                }
                
                NSAssert(false, @"WTF");
            }
        }];
    }
    RKManagedObjectThreadSafeInvocation* invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    invocation.managedObjectContext = self.managedObjectContext;
    invocation.target = self;
    invocation.selector = @selector(informDelegateOfObjectLoadWithResultDictionary:);
    [invocation setArgument:&dictionary atIndex:2];
    [invocation setManagedObjectKeyPaths:self.managedObjectKeyPaths forArgument:2];
    [invocation invokeOnMainThread];
}

// Overloaded to handle deleting an object orphaned by a failed postObject:
- (void)handleResponseError
{
    [super handleResponseError];

    if (_targetObjectID) {
        if (_deleteObjectOnFailure) {
            RKLogInfo(@"Error response encountered: Deleting existing managed object with ID: %@", _targetObjectID);
            NSManagedObject *objectToDelete = [self.objectStore objectWithID:_targetObjectID];
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

- (BOOL)isResponseMappable
{
    if ([self.response wasLoadedFromCache]) {
        NSArray *cachedObjects = [self cachedObjects];
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
