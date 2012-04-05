//
//  RKTestFactory.m
//  RKGithub
//
//  Created by Blake Watters on 2/16/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestFactory.h"

static NSString * const RKTestFactoryDefaultStoreFilename = @"RKTests.sqlite";

@interface RKTestFactory ()

@property (nonatomic, strong) RKURL *baseURL;
@property (nonatomic, strong) Class clientClass;
@property (nonatomic, strong) Class objectManagerClass;

+ (RKTestFactory *)sharedFactory;

@end

static RKTestFactory *sharedFactory = nil;

@implementation RKTestFactory

@synthesize baseURL;
@synthesize clientClass;
@synthesize objectManagerClass;

+ (void)initialize
{
    // Ensure the shared factory is initialized
    [self sharedFactory];
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
        self.clientClass = [RKClient class];
        self.objectManagerClass = [RKObjectManager class];
        
        if ([RKTestFactory respondsToSelector:@selector(didInitialize)]) {
            [RKTestFactory didInitialize];
        }
    }
    
    return self;
}

- (RKClient *)client
{
    RKClient *client = [self.clientClass clientWithBaseURL:self.baseURL];
    [RKClient setSharedClient:client];
    client.requestQueue.suspended = NO;
    
    return client;
}

- (RKObjectManager *)objectManager
{
    [RKObjectManager setDefaultMappingQueue:dispatch_queue_create("org.restkit.ObjectMapping", DISPATCH_QUEUE_SERIAL)];
    [RKObjectMapping setDefaultDateFormatters:nil];
    RKObjectManager *objectManager = [self.objectManagerClass managerWithBaseURL:self.baseURL];
    [RKObjectManager setSharedManager:objectManager];
    [RKClient setSharedClient:objectManager.client];
    
    // Force reachability determination
    [objectManager.client.reachabilityObserver getFlags];
    
    return objectManager;
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

+ (id)client
{
    return [[RKTestFactory sharedFactory] client];
}

+ (id)objectManager
{
    return [[RKTestFactory sharedFactory] objectManager];
}

+ (id)managedObjectStore
{
    [RKManagedObjectStore deleteStoreInApplicationDataDirectoryWithFilename:RKTestFactoryDefaultStoreFilename];
    RKManagedObjectStore *store = [RKManagedObjectStore objectStoreWithStoreFilename:RKTestFactoryDefaultStoreFilename];
    [store deletePersistantStore];
    [RKManagedObjectStore setDefaultObjectStore:store];
    
    return store;
}

+ (void)setUp
{
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
    NSError* error = nil;
    NSString* cachePath = [RKDirectory cachesDirectory];
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:cachePath error:&error];
    if (success) {
        RKLogInfo(@"Cleared cache directory...");
        success = [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            RKLogError(@"Failed creation of cache path '%@': %@", cachePath, [error localizedDescription]);
        }
    } else {
        RKLogError(@"Failed to clear cache path '%@': %@", cachePath, [error localizedDescription]);
    }
}

@end
