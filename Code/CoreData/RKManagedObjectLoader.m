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
@property (nonatomic, retain) NSMutableDictionary *managedObjectsByKeyPath;
@property (nonatomic, retain, readwrite) NSManagedObjectContext *managedObjectContext;

@end

@implementation RKManagedObjectLoader

@synthesize managedObjectStore = _managedObjectStore;
@synthesize targetObjectID = _targetObjectID;
@synthesize managedObjectsByKeyPath = _managedObjectsByKeyPath;
@synthesize managedObjectContext = _managedObjectContext;

- (id)initWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider
{
    self = [super initWithURL:URL mappingProvider:mappingProvider];
    if (self) {
        self.managedObjectsByKeyPath = [NSMutableDictionary dictionary];
        [self addObserver:self forKeyPath:@"managedObjectStore" options:0 context:nil];
        [self addObserver:self forKeyPath:@"targetObject" options:0 context:nil];
    }

    return self;
}

- (id)initWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider managedObjectStore:(RKManagedObjectStore *)managedObjectStore
{
    NSParameterAssert(URL);
    NSParameterAssert(mappingProvider);
    NSParameterAssert(managedObjectStore);
    
    self = [self initWithURL:URL mappingProvider:mappingProvider];
    if (self) {
        self.managedObjectStore = managedObjectStore;
    }
    
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"managedObjectStore"];
    [self removeObserver:self forKeyPath:@"targetObject"];
    [_targetObjectID release];
    [_managedObjectContext release];
    [_targetObjectID release];
    [_managedObjectsByKeyPath release];
    [_managedObjectStore release];

    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"managedObjectStore"]) {
        self.managedObjectContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] autorelease];
        self.managedObjectContext.parentContext = self.managedObjectStore.primaryManagedObjectContext;
        self.managedObjectContext.mergePolicy  = NSMergeByPropertyStoreTrumpMergePolicy;
        
        RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                                                                          cache:self.managedObjectStore.cacheStrategy];
        dataSource.tracksInsertedObjects = YES; // We need to be able to obtain permanent object ID's
        self.mappingOperationDataSource = dataSource;
        
//        // Merge changes from the primary MOC back into our MOC
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(handlePrimaryManagedObjectContextDidSaveNotification:)
//                                                     name:NSManagedObjectContextDidSaveNotification
//                                                   object:self.managedObjectStore.primaryManagedObjectContext];
    } else if ([keyPath isEqualToString:@"targetObject"]) {
        if ([self.targetObject isKindOfClass:[NSManagedObject class]]) {
            self.targetObjectID = [(NSManagedObject *)self.targetObject objectID];
        } else {
            self.targetObjectID = nil;
        }
    }
}

//- (void)handlePrimaryManagedObjectContextDidSaveNotification:(NSNotification *)notification
//{
//    [self.managedObjectContext performBlock:^{
//        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
//    }];
//}

#pragma mark - RKObjectMapperDelegate methods

// TODO: Figure out how to eliminate this...
- (void)mapper:(RKObjectMapper *)objectMapper didMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString *)keyPath usingMapping:(RKObjectMapping *)objectMapping
{
    if ([destinationObject isKindOfClass:[NSManagedObject class]]) {
        [self.managedObjectsByKeyPath setObject:destinationObject forKey:keyPath];
    }
}

#pragma mark - RKObjectLoader overrides

// Overload the target object reader to return a thread-local copy of the target object
- (id)targetObject
{
    if ([NSThread isMainThread] == NO && _targetObjectID) {
        NSAssert(self.managedObjectContext, @"Expected managedObjectContext not to be nil.");
        return [self.managedObjectContext objectWithID:self.targetObjectID];
    }

    return [super targetObject];
}

- (RKMappingResult *)performMappingWithMapper:(RKObjectMapper *)mapper
{
    __block RKMappingResult *mappingResult = nil;
    [self.managedObjectContext performBlockAndWait:^{
        mappingResult = [mapper performMapping];
    }];
    
    return mappingResult;
}

//- (BOOL)prepareURLRequest
//{
//    // NOTE: There is an important sequencing issue here. You MUST save the
//    // managed object context before retaining the objectID or you will run
//    // into an error where the object context cannot be saved. We do this
//    // right before send to avoid sequencing issues where the target object is
//    // set before the managed object store.
//    if (self.targetObject && [self.targetObject isKindOfClass:[NSManagedObject class]]) {
//        self.deleteObjectOnFailure = [(NSManagedObject *)self.targetObject isNew];
//        [self.objectStore save:nil];
//        self.targetObjectID = [[(NSManagedObject *)self.targetObject objectID] retain];
//    }
//
//    return [super prepareURLRequest];
//}

- (NSArray *)cachedObjects
{
    NSFetchRequest *fetchRequest = [self.mappingProvider fetchRequestForResourcePath:self.resourcePath];
    if (fetchRequest) {
        NSError *error = nil;
        NSArray *cachedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (! cachedObjects) {
            RKLogError(@"Failed to retrieve cached objects with error: %@", error);
        }
        return cachedObjects;
    }

    return nil;
}

- (void)deleteCachedObjectsMissingFromResult:(RKMappingResult *)result
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
                [self.managedObjectContext deleteObject:object];
            }
        }
    } else {
        RKLogWarning(@"Unable to perform cleanup of server-side object deletions: unable to determine resource path.");
    }
}

// NOTE: We are on the background thread here, be mindful of Core Data's threading needs
- (void)processMappingResult:(RKMappingResult *)result
{
    NSAssert(_sentSynchronously || ![NSThread isMainThread], @"Mapping result processing should occur on a background thread");
    if (self.targetObjectID && self.targetObject && self.method == RKRequestMethodDELETE) {
        NSManagedObject *backgroundThreadObject = [self.managedObjectContext objectWithID:self.targetObjectID];
        RKLogInfo(@"Deleting local object %@ due to DELETE request", backgroundThreadObject);
        [self.managedObjectContext deleteObject:backgroundThreadObject];
    }

    // If the response was successful, save the store...
    if ([self.response isSuccessful]) {
        [self deleteCachedObjectsMissingFromResult:result];
        __block BOOL success = NO;
        __block NSError *error = nil;
            
        NSArray *insertedObjects = [(RKManagedObjectMappingOperationDataSource *)self.mappingOperationDataSource insertedObjects];
        RKLogDebug(@"Obtaining permanent object ID's for %d objects", [insertedObjects count]);
        success = [self.managedObjectContext obtainPermanentIDsForObjects:insertedObjects error:&error];
        if (! success) {
            RKLogError(@"Failed to obtain permanent object ID's for all managed objects. Error: %@", error);
        }
        
        [self.managedObjectContext performBlockAndWait:^{
            success = [self.managedObjectContext save:&error];
            NSLog(@"Saved MOC success = %d. Error: %@", success, error);
        }];
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
            }
        }];
    }
    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    invocation.mainQueueManagedObjectContext = self.managedObjectStore.mainQueueManagedObjectContext;
    invocation.privateQueueManagedObjectContext = self.managedObjectContext;
    invocation.target = self;
    invocation.selector = @selector(informDelegateOfObjectLoadWithResultDictionary:);
    [invocation setArgument:&dictionary atIndex:2];
    [invocation setManagedObjectKeyPaths:[NSSet setWithArray:[self.managedObjectsByKeyPath allKeys]] forArgument:2];
    [invocation invokeOnMainThread];
}

// Overloaded to handle deleting an object orphaned by a failed postObject:
// TODO: Should be able to eliminate this...
//- (void)handleResponseError
//{
//    [super handleResponseError];
//
//    if (_targetObjectID) {
//        if (_deleteObjectOnFailure) {
//            RKLogInfo(@"Error response encountered: Deleting existing managed object with ID: %@", _targetObjectID);
//            NSManagedObject *objectToDelete = [self.objectStore objectWithID:_targetObjectID];
//            if (objectToDelete) {
//                [[self.objectStore managedObjectContextForCurrentThread] deleteObject:objectToDelete];
//                [self.objectStore save:nil];
//            } else {
//                RKLogWarning(@"Unable to delete existing managed object with ID: %@. Object not found in the store.", _targetObjectID);
//            }
//        } else {
//            RKLogDebug(@"Skipping deletion of existing managed object");
//        }
//    }
//}

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


@implementation RKManagedObjectLoader (Deprecations)

+ (id)loaderWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider objectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE
{
    return [[[self alloc] initWithURL:URL mappingProvider:mappingProvider objectStore:objectStore] autorelease];
}

- (id)initWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider objectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE
{
    return [self initWithURL:URL mappingProvider:mappingProvider managedObjectStore:objectStore];
}

@end
