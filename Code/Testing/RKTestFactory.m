//
//  RKTestFactory.m
//  RestKit
//
//  Created by Blake Watters on 2/16/12.
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

#import "AFHTTPClient.h"
#import "RKTestFactory.h"
#import "RKLog.h"
#import "RKObjectManager.h"
#import "RKPathUtilities.h"
#import "RKMIMETypeSerialization.h"
#import "RKManagedObjectStore.h"

// Expose MIME Type singleton and initialization routine
@interface RKMIMETypeSerialization ()
+ (RKMIMETypeSerialization *)sharedSerialization;
- (void)addRegistrationsForKnownSerializations;
@end

@interface RKTestFactory ()

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSMutableDictionary *factoryBlocks;
@property (nonatomic, strong) NSMutableDictionary *sharedObjectsByFactoryName;
@property (nonatomic, copy) void (^setUpBlock)();
@property (nonatomic, copy) void (^tearDownBlock)();

+ (RKTestFactory *)sharedFactory;
- (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block;
- (id)objectFromFactory:(NSString *)factoryName properties:(NSDictionary *)properties;
- (void)defineDefaultFactories;

@end

@implementation RKTestFactory

+ (void)initialize
{
    // Ensure the shared factory is initialized
    [self sharedFactory];
}

+ (RKTestFactory *)sharedFactory
{
    static RKTestFactory *sharedFactory = nil;
    if (! sharedFactory) {
        sharedFactory = [RKTestFactory new];
    }

    return sharedFactory;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.baseURL = [NSURL URLWithString:@"http://127.0.0.1:4567"];
        self.factoryBlocks = [NSMutableDictionary new];
        self.sharedObjectsByFactoryName = [NSMutableDictionary new];
        [self defineDefaultFactories];
    }

    return self;
}

- (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block
{
    [self.factoryBlocks setObject:[block copy] forKey:factoryName];
}

- (id)objectFromFactory:(NSString *)factoryName properties:(NSDictionary *)properties
{
    id (^block)() = [self.factoryBlocks objectForKey:factoryName];
    NSAssert(block, @"No factory is defined with the name '%@'", factoryName);

    id object = block();
    [object setValuesForKeysWithDictionary:properties];
    return object;
}

- (id)sharedObjectFromFactory:(NSString *)factoryName
{
    id sharedObject = [self.sharedObjectsByFactoryName objectForKey:factoryName];
    if (! sharedObject) {
        sharedObject = [self objectFromFactory:factoryName properties:nil];
        [self.sharedObjectsByFactoryName setObject:sharedObject forKey:factoryName];
    }
    return sharedObject;
}

- (void)defineDefaultFactories
{
    [self defineFactory:RKTestFactoryDefaultNamesClient withBlock:^id {
        __block AFHTTPClient *client;
        RKLogSilenceComponentWhileExecutingBlock(RKlcl_cRestKitSupport, ^{
            client = [AFHTTPClient clientWithBaseURL:self.baseURL];
        });

        return client;
    }];

    [self defineFactory:RKTestFactoryDefaultNamesObjectManager withBlock:^id {
        __block RKObjectManager *objectManager;
        RKLogSilenceComponentWhileExecutingBlock(RKlcl_cRestKitSupport, ^{
            objectManager = [RKObjectManager managerWithBaseURL:self.baseURL];
        });

        return objectManager;
    }];

    [self defineFactory:RKTestFactoryDefaultNamesManagedObjectStore withBlock:^id {
        NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:RKTestFactoryDefaultStoreFilename];
        RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] init];
        NSError *error;
        NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
        if (persistentStore) {
            BOOL success = [managedObjectStore resetPersistentStores:&error];
            if (! success) {
                RKLogError(@"Failed to reset persistent store: %@", error);
            }
        }

        return managedObjectStore;
    }];
}

#pragma mark - Public Static Interface

+ (NSURL *)baseURL
{
    return [RKTestFactory sharedFactory].baseURL;
}

+ (void)setBaseURL:(NSURL *)URL
{
    [RKTestFactory sharedFactory].baseURL = URL;
}

+ (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block
{
    [[RKTestFactory sharedFactory] defineFactory:factoryName withBlock:block];
}

+ (id)objectFromFactory:(NSString *)factoryName properties:(NSDictionary *)properties
{
    return [[RKTestFactory sharedFactory] objectFromFactory:factoryName properties:properties];
}

+ (id)objectFromFactory:(NSString *)factoryName
{
    return [[RKTestFactory sharedFactory] objectFromFactory:factoryName properties:nil];
}

+ (id)sharedObjectFromFactory:(NSString *)factoryName
{
    return [[RKTestFactory sharedFactory] sharedObjectFromFactory:factoryName];
}

+ (id)insertManagedObjectForEntityForName:(NSString *)entityName
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                           withProperties:(NSDictionary *)properties
{
    __block id managedObject;
    __block NSError *error;
    __block BOOL success;
    if (! managedObjectContext) managedObjectContext = [[RKTestFactory managedObjectStore] mainQueueManagedObjectContext];
    [managedObjectContext performBlockAndWait:^{
        managedObject = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:managedObjectContext];
        success = [managedObjectContext obtainPermanentIDsForObjects:@[managedObject] error:&error];
        if (! success) {
            RKLogWarning(@"Failed to obtain permanent objectID for managed object: %@", managedObject);
            RKLogCoreDataError(error);
        }
        [managedObject setValuesForKeysWithDictionary:properties];
    }];
    return managedObject;
}

+ (NSSet *)factoryNames
{
    return [NSSet setWithArray:[[RKTestFactory sharedFactory].factoryBlocks allKeys]];
}

+ (id)client
{
    return [self sharedObjectFromFactory:RKTestFactoryDefaultNamesClient];
}

+ (id)objectManager
{
    return [self sharedObjectFromFactory:RKTestFactoryDefaultNamesObjectManager];
}

+ (id)managedObjectStore
{
    return [self sharedObjectFromFactory:RKTestFactoryDefaultNamesManagedObjectStore];
}

+ (void)setSetupBlock:(void (^)())block
{
    [RKTestFactory sharedFactory].setUpBlock = block;
}

+ (void)setTearDownBlock:(void (^)())block
{
    [RKTestFactory sharedFactory].tearDownBlock = block;
}

+ (void)setUp
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // On initial set up, perform a tear down to clear any state from the application launch
        [self tearDown];
    });

    [[RKTestFactory sharedFactory].sharedObjectsByFactoryName removeAllObjects];
    [RKObjectManager setSharedManager:nil];
    [RKManagedObjectStore setDefaultStore:nil];
    
    // Restore the default MIME Type Serializations in case a test has manipulated the registry
    [[RKMIMETypeSerialization sharedSerialization] addRegistrationsForKnownSerializations];

    // Delete the store if it exists
    NSString *path = [RKApplicationDataDirectory() stringByAppendingPathComponent:RKTestFactoryDefaultStoreFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    // Clear the NSURLCache
    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    if ([RKTestFactory sharedFactory].setUpBlock) [RKTestFactory sharedFactory].setUpBlock();
}

+ (void)tearDown
{
    // Cancel any network operations and clear the cache
    [[RKObjectManager sharedManager].operationQueue cancelAllOperations];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    // Cancel any object mapping in the response mapping queue
    [[RKObjectRequestOperation responseMappingQueue] cancelAllOperations];

    // Ensure the existing defaultStore is shut down
    [[NSNotificationCenter defaultCenter] removeObserver:[RKManagedObjectStore defaultStore]];
    if ([[RKManagedObjectStore defaultStore] respondsToSelector:@selector(stopIndexingPersistentStoreManagedObjectContext)]) {
        // Search component is optional
        [[RKManagedObjectStore defaultStore] performSelector:@selector(stopIndexingPersistentStoreManagedObjectContext)];
        
        if ([[RKManagedObjectStore defaultStore] respondsToSelector:@selector(searchIndexer)]) {
            id searchIndexer = [[RKManagedObjectStore defaultStore] valueForKey:@"searchIndexer"];
            [searchIndexer performSelector:@selector(cancelAllIndexingOperations)];
        }
    }
    
    [[RKTestFactory sharedFactory].sharedObjectsByFactoryName removeAllObjects];
    [RKObjectManager setSharedManager:nil];
    [RKManagedObjectStore setDefaultStore:nil];

    if ([RKTestFactory sharedFactory].tearDownBlock) [RKTestFactory sharedFactory].tearDownBlock();
}

@end
