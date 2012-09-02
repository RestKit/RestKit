//
//  RKTestFactory.m
//  RestKit
//
//  Created by Blake Watters on 2/16/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "AFHTTPClient.h"
#import "RKTestFactory.h"

@interface RKTestFactory ()

@property (nonatomic, strong) RKURL *baseURL;
@property (nonatomic, strong) NSString *managedObjectStoreFilename;
@property (nonatomic, strong) NSMutableDictionary *factoryBlocks;

+ (RKTestFactory *)sharedFactory;
- (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block;
- (id)objectFromFactory:(NSString *)factoryName;
- (void)defineDefaultFactories;

@end

static RKTestFactory *sharedFactory = nil;

@implementation RKTestFactory


+ (void)initialize
{
    // Ensure the shared factory is initialized
    [self sharedFactory];

    if ([RKTestFactory respondsToSelector:@selector(didInitialize)]) {
        [RKTestFactory didInitialize];
    }
}

+ (RKTestFactory *)sharedFactory
{
    if (! sharedFactory) {
        sharedFactory = [RKTestFactory new];
    }

    return sharedFactory;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.baseURL = [RKURL URLWithString:@"http://127.0.0.1:4567"];
        self.managedObjectStoreFilename = RKTestFactoryDefaultStoreFilename;
        self.factoryBlocks = [NSMutableDictionary new];
        [self defineDefaultFactories];
    }

    return self;
}

- (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block
{
    [self.factoryBlocks setObject:[block copy] forKey:factoryName];
}

- (id)objectFromFactory:(NSString *)factoryName
{
    id (^block)() = [self.factoryBlocks objectForKey:factoryName];
    NSAssert(block, @"No factory is defined with the name '%@'", factoryName);

    return block();
}

- (void)defineDefaultFactories
{
    [self defineFactory:RKTestFactoryDefaultNamesClient withBlock:^id {
        __block AFHTTPClient *client;

        RKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitNetworkReachability, ^{
            RKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitSupport, ^{
                client = [AFHTTPClient clientWithBaseURL:self.baseURL];
            });
        });

        return client;
    }];

    [self defineFactory:RKTestFactoryDefaultNamesObjectManager withBlock:^id {
        __block RKObjectManager *objectManager;

        RKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitNetworkReachability, ^{
            RKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitSupport, ^{
                objectManager = [RKObjectManager managerWithBaseURL:self.baseURL];
            });
        });

        return objectManager;
    }];

    [self defineFactory:RKTestFactoryDefaultNamesManagedObjectStore withBlock:^id {
        NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:RKTestFactoryDefaultStoreFilename];
        RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] init];
        NSError *error;
        NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil error:&error];
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

+ (RKURL *)baseURL
{
    return [RKTestFactory sharedFactory].baseURL;
}

+ (void)setBaseURL:(RKURL *)URL
{
    [RKTestFactory sharedFactory].baseURL = URL;
}

+ (NSString *)baseURLString
{
    return [[[RKTestFactory sharedFactory] baseURL] absoluteString];
}

+ (void)setBaseURLString:(NSString *)baseURLString
{
    [[RKTestFactory sharedFactory] setBaseURL:[RKURL URLWithString:baseURLString]];
}

+ (NSString *)managedObjectStoreFilename
{
   return [RKTestFactory sharedFactory].managedObjectStoreFilename;
}

+ (void)setManagedObjectStoreFilename:(NSString *)managedObjectStoreFilename
{
    [RKTestFactory sharedFactory].managedObjectStoreFilename = managedObjectStoreFilename;
}

+ (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block
{
    [[RKTestFactory sharedFactory] defineFactory:factoryName withBlock:block];
}

+ (id)objectFromFactory:(NSString *)factoryName
{
    return [[RKTestFactory sharedFactory] objectFromFactory:factoryName];
}

+ (NSSet *)factoryNames
{
    return [NSSet setWithArray:[[RKTestFactory sharedFactory].factoryBlocks allKeys]];
}

+ (id)client
{
    AFHTTPClient *client = [self objectFromFactory:RKTestFactoryDefaultNamesClient];
    return client;
}

+ (id)objectManager
{
    RKObjectManager *objectManager = [self objectFromFactory:RKTestFactoryDefaultNamesObjectManager];
    [RKObjectManager setSharedManager:objectManager];
    return objectManager;
}

+ (id)managedObjectStore
{
    RKManagedObjectStore *managedObjectStore = [self objectFromFactory:RKTestFactoryDefaultNamesManagedObjectStore];
    [RKManagedObjectStore setDefaultStore:managedObjectStore];

    return managedObjectStore;
}

+ (void)setUp
{
    [RKObjectManager setSharedManager:nil];
    [RKManagedObjectStore setDefaultStore:nil];
    [RKObjectManager setDefaultMappingQueue:nil];
    [RKObjectMapping setDefaultDateFormatters:nil];

    // Delete the store if it exists
    NSString *path = [RKApplicationDataDirectory() stringByAppendingPathComponent:RKTestFactoryDefaultStoreFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }

    if ([self respondsToSelector:@selector(didSetUp)]) {
        [self didSetUp];
    }
}

+ (void)tearDown
{
    [RKObjectManager setSharedManager:nil];
    [RKManagedObjectStore setDefaultStore:nil];

    if ([self respondsToSelector:@selector(didTearDown)]) {
        [self didTearDown];
    }
}

+ (void)clearCacheDirectory
{
    NSError *error = nil;
    NSString *cachePath = RKCachesDirectory();
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:cachePath error:&error];
    if (success) {
        RKLogDebug(@"Cleared cache directory...");
        success = [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            RKLogError(@"Failed creation of cache path '%@': %@", cachePath, [error localizedDescription]);
        }
    } else {
        RKLogError(@"Failed to clear cache path '%@': %@", cachePath, [error localizedDescription]);
    }
}

@end
