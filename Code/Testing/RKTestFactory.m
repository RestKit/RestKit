//
//  RKTestFactory.m
//  RKGithub
//
//  Created by Blake Watters on 2/16/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

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

@synthesize baseURL = _baseURL;
@synthesize managedObjectStoreFilename = _managedObjectStoreFilename;
@synthesize factoryBlocks = _factoryBlocks;

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
        __block RKClient *client;

        RKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitNetworkReachability, ^{
            RKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitSupport, ^{
                client = [RKClient clientWithBaseURL:self.baseURL];
                client.requestQueue.suspended = NO;
                [client.reachabilityObserver getFlags];
            });
        });

        return client;
    }];

    [self defineFactory:RKTestFactoryDefaultNamesObjectManager withBlock:^id {
        __block RKObjectManager *objectManager;

        RKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitNetworkReachability, ^{
            RKLogSilenceComponentWhileExecutingBlock(lcl_cRestKitSupport, ^{
                objectManager = [RKObjectManager managerWithBaseURL:self.baseURL];
                RKObjectMappingProvider *mappingProvider = [self objectFromFactory:RKTestFactoryDefaultNamesMappingProvider];
                objectManager.mappingProvider = mappingProvider;

                // Force reachability determination
                [objectManager.client.reachabilityObserver getFlags];
            });
        });

        return objectManager;
    }];

    [self defineFactory:RKTestFactoryDefaultNamesMappingProvider withBlock:^id {
        RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
        return mappingProvider;
    }];

    [self defineFactory:RKTestFactoryDefaultNamesManagedObjectStore withBlock:^id {
        NSString *storePath = [[RKDirectory applicationDataDirectory] stringByAppendingPathComponent:RKTestFactoryDefaultStoreFilename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
            [RKManagedObjectStore deleteStoreInApplicationDataDirectoryWithFilename:RKTestFactoryDefaultStoreFilename];
        }
        RKManagedObjectStore *store = [RKManagedObjectStore objectStoreWithStoreFilename:RKTestFactoryDefaultStoreFilename];

        return store;
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
    RKClient *client = [self objectFromFactory:RKTestFactoryDefaultNamesClient];
    [RKClient setSharedClient:client];

    return client;
}

+ (id)objectManager
{
    RKObjectManager *objectManager = [self objectFromFactory:RKTestFactoryDefaultNamesObjectManager];
    [RKObjectManager setSharedManager:objectManager];
    [RKClient setSharedClient:objectManager.client];

    return objectManager;
}

+ (id)mappingProvider
{
    RKObjectMappingProvider *mappingProvider = [self objectFromFactory:RKTestFactoryDefaultNamesMappingProvider];

    return mappingProvider;
}

+ (id)managedObjectStore
{
    RKManagedObjectStore *objectStore = [self objectFromFactory:RKTestFactoryDefaultNamesManagedObjectStore];
    [RKManagedObjectStore setDefaultObjectStore:objectStore];

    return objectStore;
}

+ (void)setUp
{
    [RKObjectManager setDefaultMappingQueue:dispatch_queue_create("org.restkit.ObjectMapping", DISPATCH_QUEUE_SERIAL)];
    [RKObjectMapping setDefaultDateFormatters:nil];

    // Delete the store if it exists
    NSString *path = [[RKDirectory applicationDataDirectory] stringByAppendingPathComponent:RKTestFactoryDefaultStoreFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [RKManagedObjectStore deleteStoreInApplicationDataDirectoryWithFilename:RKTestFactoryDefaultStoreFilename];
    }

    if ([self respondsToSelector:@selector(didSetUp)]) {
        [self didSetUp];
    }
}

+ (void)tearDown
{
    [RKObjectManager setSharedManager:nil];
    [RKClient setSharedClient:nil];
    [RKManagedObjectStore setDefaultObjectStore:nil];

    if ([self respondsToSelector:@selector(didTearDown)]) {
        [self didTearDown];
    }
}

+ (void)clearCacheDirectory
{
    NSError *error = nil;
    NSString *cachePath = [RKDirectory cachesDirectory];
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
