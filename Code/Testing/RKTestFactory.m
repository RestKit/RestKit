//
//  RKTestFactory.m
//  RKGithub
//
//  Created by Blake Watters on 2/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestFactory.h"

static RKTestFactory *sharedFactory = nil;

@implementation RKTestFactory

@synthesize baseURL;
@synthesize clientClass;
@synthesize objectManagerClass;

+ (RKTestFactory *)sharedFactory {
    if (! sharedFactory) {
        sharedFactory = [RKTestFactory new];
    }
    
    return sharedFactory;
}

- (id)init {
    self = [super init];
    if (self) {
        self.baseURL = [RKURL URLWithString:@"http://localhost:4567"];
        self.clientClass = [RKClient class];
        self.objectManagerClass = [RKObjectManager class];
        
        [self didInitialize];
    }
    
    return self;
}

- (RKClient *)client {
    RKClient *client = [self.clientClass clientWithBaseURL:self.baseURL];
    [RKClient setSharedClient:client];
    client.requestQueue.suspended = NO;
    
    return client;
}

- (RKObjectManager *)objectManager {
    [RKObjectManager setDefaultMappingQueue:dispatch_queue_create("org.restkit.ObjectMapping", DISPATCH_QUEUE_SERIAL)];
    [RKObjectMapping setDefaultDateFormatters:nil];
    RKObjectManager *objectManager = [self.objectManagerClass managerWithBaseURL:self.baseURL];
    [RKObjectManager setSharedManager:objectManager];
    [RKClient setSharedClient:objectManager.client];
    
    // Force reachability determination
    [objectManager.client.reachabilityObserver getFlags];
    
    return objectManager;
}

- (RKManagedObjectStore *)objectStore {
    RKManagedObjectStore *store = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKTests.sqlite"];
    [store deletePersistantStore];
    [RKObjectManager sharedManager].objectStore = store;
    return store;
}

- (void)setUp {
    [self didSetUp];
}

- (void)tearDown {
    [RKObjectManager setSharedManager:nil];
    [RKClient setSharedClient:nil];
    
    [self didTearDown];
}

#pragma - Customization Hooks

- (void)didInitialize {
    // Should be overloaded via a category
}

- (void)didSetUp {
    // Should be overloaded via a category
}

- (void)didTearDown {
    // Should be overloaded via a category    
}

@end

@implementation RKTestFactory (ConvenienceAliases)

+ (void)setUp {
    [[RKTestFactory sharedFactory] setUp];
}

+ (RKURL *)baseURL {
    return [RKTestFactory sharedFactory].baseURL;
}

+ (void)setBaseURL:(RKURL *)URL {
    [RKTestFactory sharedFactory].baseURL = URL;
}

+ (NSString *)baseURLString {
    return [[[RKTestFactory sharedFactory] baseURL] absoluteString];
}

+ (void)setBaseURLString:(NSString *)baseURLString {
    [[RKTestFactory sharedFactory] setBaseURL:[RKURL URLWithString:baseURLString]];
}

+ (id)client {
    return [[RKTestFactory sharedFactory] client];
}

+ (id)objectManager {
    return [[RKTestFactory sharedFactory] objectManager];
}

+ (id)objectStore {
    return [[RKTestFactory sharedFactory] objectStore];
}

+ (void)tearDown {
    [[RKTestFactory sharedFactory] tearDown];
}

@end
