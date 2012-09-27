//
//  RKTestFactory.m
//  RestKit
//
//  Created by Blake Watters on 2/16/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "AFHTTPClient.h"
#import "RKTestFactory.h"
#import "RKLog.h"
#import "RKObjectManager.h"
#import "RKPathUtilities.h"

@interface RKTestFactory ()

@property (nonatomic, strong) NSURL *baseURL;
@property (nonatomic, strong) NSString *managedObjectStoreFilename;
@property (nonatomic, strong) NSMutableDictionary *factoryBlocks;

+ (RKTestFactory *)sharedFactory;
- (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block;
- (id)objectFromFactory:(NSString *)factoryName properties:(NSDictionary *)properties;
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
        self.baseURL = [NSURL URLWithString:@"http://127.0.0.1:4567"];
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

- (id)objectFromFactory:(NSString *)factoryName properties:(NSDictionary *)properties
{
    id (^block)() = [self.factoryBlocks objectForKey:factoryName];
    NSAssert(block, @"No factory is defined with the name '%@'", factoryName);

    id object = block();
    [object setValuesForKeysWithDictionary:properties];
    return object;
}

- (void)defineDefaultFactories
{
    [self defineFactory:RKTestFactoryDefaultNamesClient withBlock:^id {
        __block AFHTTPClient *client;

        RKLogSilenceComponentWhileExecutingBlock(RKlcl_cRestKitNetworkReachability, ^{
            RKLogSilenceComponentWhileExecutingBlock(RKlcl_cRestKitSupport, ^{
                client = [AFHTTPClient clientWithBaseURL:self.baseURL];
            });
        });

        return client;
    }];

    [self defineFactory:RKTestFactoryDefaultNamesObjectManager withBlock:^id {
        __block RKObjectManager *objectManager;

        RKLogSilenceComponentWhileExecutingBlock(RKlcl_cRestKitNetworkReachability, ^{
            RKLogSilenceComponentWhileExecutingBlock(RKlcl_cRestKitSupport, ^{
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

+ (NSURL *)baseURL
{
    return [RKTestFactory sharedFactory].baseURL;
}

+ (void)setBaseURL:(NSURL *)URL
{
    [RKTestFactory sharedFactory].baseURL = URL;
}

+ (NSString *)baseURLString
{
    return [[[RKTestFactory sharedFactory] baseURL] absoluteString];
}

+ (void)setBaseURLString:(NSString *)baseURLString
{
    [[RKTestFactory sharedFactory] setBaseURL:[NSURL URLWithString:baseURLString]];
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

+ (id)objectFromFactory:(NSString *)factoryName properties:(NSDictionary *)properties
{
    return [[RKTestFactory sharedFactory] objectFromFactory:factoryName properties:properties];
}

+ (id)objectFromFactory:(NSString *)factoryName
{
    return [[RKTestFactory sharedFactory] objectFromFactory:factoryName properties:nil];
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
    return [self objectFromFactory:RKTestFactoryDefaultNamesClient properties:nil];
}

+ (id)objectManager
{
    return [self objectFromFactory:RKTestFactoryDefaultNamesObjectManager properties:nil];
}

+ (id)managedObjectStore
{
    return [self objectFromFactory:RKTestFactoryDefaultNamesManagedObjectStore properties:nil];
}

+ (void)setUp
{
    [RKObjectManager setSharedManager:nil];
    [RKManagedObjectStore setDefaultStore:nil];

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
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];

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
