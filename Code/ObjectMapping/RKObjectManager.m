//
//  RKObjectManager.m
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
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
#import "RKObjectSerializer.h"
#import "RKManagedObjectStore.h"
#import "RKManagedObjectLoader.h"
#import "Support.h"

NSString * const RKObjectManagerDidBecomeOfflineNotification = @"RKDidEnterOfflineModeNotification";
NSString * const RKObjectManagerDidBecomeOnlineNotification = @"RKDidEnterOnlineModeNotification";

//////////////////////////////////
// Shared Instances

static RKObjectManager  *sharedManager = nil;
static NSOperationQueue *defaultMappingQueue = nil;

///////////////////////////////////

@interface RKObjectManager ()
@property (nonatomic, assign, readwrite) RKObjectManagerNetworkStatus networkStatus;
@end

@implementation RKObjectManager

@synthesize client = _client;
@synthesize managedObjectStore = _managedObjectStore;
@synthesize mappingProvider = _mappingProvider;
@synthesize serializationMIMEType = _serializationMIMEType;
@synthesize networkStatus = _networkStatus;
@synthesize mappingQueue = _mappingQueue;

+ (NSOperationQueue *)defaultMappingQueue
{
    if (! defaultMappingQueue) {
        defaultMappingQueue = [NSOperationQueue new];
        defaultMappingQueue.name = @"org.restkit.ObjectMapping";
        defaultMappingQueue.maxConcurrentOperationCount = 1;
    }

    return defaultMappingQueue;
}

+ (void)setDefaultMappingQueue:(NSOperationQueue *)newDefaultMappingQueue
{
    if (defaultMappingQueue) {
        [defaultMappingQueue release];
        defaultMappingQueue = nil;
    }

    if (newDefaultMappingQueue) {
        [newDefaultMappingQueue retain];
        defaultMappingQueue = newDefaultMappingQueue;
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        _mappingProvider = [RKObjectMappingProvider new];
        _networkStatus = RKObjectManagerNetworkStatusUnknown;

        self.serializationMIMEType = RKMIMETypeFormURLEncoded;
        self.mappingQueue = [RKObjectManager defaultMappingQueue];

        [self addObserver:self
               forKeyPath:@"client.reachabilityObserver"
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                  context:nil];

        // Set shared manager if nil
        if (nil == sharedManager) {
            [RKObjectManager setSharedManager:self];
        }
    }

    return self;
}

- (id)initWithBaseURL:(RKURL *)baseURL
{
    self = [self init];
    if (self) {
        self.client = [RKClient clientWithBaseURL:baseURL];
        self.acceptMIMEType = RKMIMETypeJSON;
    }

    return self;
}

+ (RKObjectManager *)sharedManager
{
    return sharedManager;
}

+ (void)setSharedManager:(RKObjectManager *)manager
{
    [manager retain];
    [sharedManager release];
    sharedManager = manager;
}

+ (RKObjectManager *)managerWithBaseURLString:(NSString *)baseURLString
{
    return [self managerWithBaseURL:[RKURL URLWithString:baseURLString]];
}

+ (RKObjectManager *)managerWithBaseURL:(NSURL *)baseURL
{
    RKObjectManager *manager = [[[self alloc] initWithBaseURL:[RKURL URLWithBaseURL:baseURL]] autorelease];
    return manager;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"client.reachabilityObserver"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_client release];
    [_managedObjectStore release];
    [_serializationMIMEType release];
    [_mappingProvider release];

    [super dealloc];
}

- (BOOL)isOnline
{
    return (_networkStatus == RKObjectManagerNetworkStatusOnline);
}

- (BOOL)isOffline
{
    return (_networkStatus == RKObjectManagerNetworkStatusOffline);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"client.reachabilityObserver"]) {
        [self reachabilityObserverDidChange:change];
    }
}

- (void)reachabilityObserverDidChange:(NSDictionary *)change
{
    RKReachabilityObserver *oldReachabilityObserver = [change objectForKey:NSKeyValueChangeOldKey];
    RKReachabilityObserver *newReachabilityObserver = [change objectForKey:NSKeyValueChangeNewKey];

    if (! [oldReachabilityObserver isEqual:[NSNull null]]) {
        RKLogDebug(@"Reachability observer changed for RKClient %@ of RKObjectManager %@, stopping observing reachability changes", self.client, self);
        [[NSNotificationCenter defaultCenter] removeObserver:self name:RKReachabilityDidChangeNotification object:oldReachabilityObserver];
    }

    if (! [newReachabilityObserver isEqual:[NSNull null]]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:RKReachabilityDidChangeNotification
                                                   object:newReachabilityObserver];

        RKLogDebug(@"Reachability observer changed for client %@ of object manager %@, starting observing reachability changes", self.client, self);
    }

    // Initialize current Network Status
    if ([self.client.reachabilityObserver isReachabilityDetermined]) {
        BOOL isNetworkReachable = [self.client.reachabilityObserver isNetworkReachable];
        self.networkStatus = isNetworkReachable ? RKObjectManagerNetworkStatusOnline : RKObjectManagerNetworkStatusOffline;
    } else {
        self.networkStatus = RKObjectManagerNetworkStatusUnknown;
    }
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    BOOL isHostReachable = [self.client.reachabilityObserver isNetworkReachable];

    _networkStatus = isHostReachable ? RKObjectManagerNetworkStatusOnline : RKObjectManagerNetworkStatusOffline;

    if (isHostReachable) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOnlineNotification object:self];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:self];
    }
}

- (void)setAcceptMIMEType:(NSString *)MIMEType
{
    [self.client setValue:MIMEType forHTTPHeaderField:@"Accept"];
}

- (NSString *)acceptMIMEType
{
    return [self.client.HTTPHeaders valueForKey:@"Accept"];
}

/////////////////////////////////////////////////////////////
#pragma mark - Object Collection Loaders

- (Class)objectLoaderClass
{
    Class managedObjectLoaderClass = NSClassFromString(@"RKManagedObjectLoader");
    if (self.managedObjectStore && managedObjectLoaderClass) {
        return managedObjectLoaderClass;
    }

    return [RKObjectLoader class];
}

- (id)loaderWithResourcePath:(NSString *)resourcePath
{
    RKURL *URL = [self.baseURL URLByAppendingResourcePath:resourcePath];
    return [self loaderWithURL:URL];
}

- (id)loaderWithURL:(RKURL *)URL
{
    RKObjectLoader *loader = [[self objectLoaderClass] loaderWithURL:URL mappingProvider:self.mappingProvider];
    loader.configurationDelegate = self;
    if ([loader isKindOfClass:[RKManagedObjectLoader class]]) {
        RKManagedObjectLoader *managedObjectLoader = (RKManagedObjectLoader *)loader;
        managedObjectLoader.managedObjectContext = self.managedObjectStore.primaryManagedObjectContext;
        managedObjectLoader.mainQueueManagedObjectContext = self.managedObjectStore.mainQueueManagedObjectContext;
        managedObjectLoader.managedObjectCache = self.managedObjectStore.managedObjectCache;
    }
    [self configureObjectLoader:loader];

    return loader;
}

- (NSURL *)baseURL
{
    return self.client.baseURL;
}

- (RKObjectPaginator *)paginatorWithResourcePathPattern:(NSString *)resourcePathPattern
{
    RKURL *patternURL = [[self baseURL] URLByAppendingResourcePath:resourcePathPattern];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL
                                                              mappingProvider:self.mappingProvider];
    paginator.configurationDelegate = self;
    return paginator;
}

- (id)loaderForObject:(id<NSObject>)object method:(RKRequestMethod)method
{
    RKURL *URL = [self.router URLForObject:object method:method];
    RKObjectLoader *loader = [self loaderWithURL:URL];
    loader.method = method;
    loader.sourceObject = object;
    loader.serializationMIMEType = self.serializationMIMEType;
    loader.serializationMapping = [self.mappingProvider serializationMappingForClass:[object class]];

    RKMapping *objectMapping = URL.resourcePath ? [self.mappingProvider objectMappingForResourcePath:URL.resourcePath] : nil;
    if (objectMapping == nil || ([objectMapping isKindOfClass:[RKObjectMapping class]] && [object isMemberOfClass:[(RKObjectMapping *)objectMapping objectClass]])) {
        loader.targetObject = object;
    } else {
        loader.targetObject = nil;
    }

    return loader;
}

- (void)loadObjectsAtResourcePath:(NSString *)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate
{
    RKObjectLoader *loader = [self loaderWithResourcePath:resourcePath];
    loader.delegate = delegate;
    loader.method = RKRequestMethodGET;

    [loader send];
}

/////////////////////////////////////////////////////////////
#pragma mark - Object Instance Loaders

- (void)getObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate
{
    RKObjectLoader *loader = [self loaderForObject:object method:RKRequestMethodGET];
    loader.delegate = delegate;
    [loader send];
}

- (void)postObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate
{
    RKObjectLoader *loader = [self loaderForObject:object method:RKRequestMethodPOST];
    loader.delegate = delegate;
    [loader send];
}

- (void)putObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate
{
    RKObjectLoader *loader = [self loaderForObject:object method:RKRequestMethodPUT];
    loader.delegate = delegate;
    [loader send];
}

- (void)deleteObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate
{
    RKObjectLoader *loader = [self loaderForObject:object method:RKRequestMethodDELETE];
    loader.delegate = delegate;
    [loader send];
}

#if NS_BLOCKS_AVAILABLE

#pragma mark - Block Configured Object Loaders

- (void)loadObjectsAtResourcePath:(NSString *)resourcePath usingBlock:(void(^)(RKObjectLoader *))block
{
    RKObjectLoader *loader = [self loaderWithResourcePath:resourcePath];
    loader.method = RKRequestMethodGET;

    // Yield to the block for setup
    block(loader);

    [loader send];
}

- (void)sendObject:(id<NSObject>)object toResourcePath:(NSString *)resourcePath usingBlock:(void(^)(RKObjectLoader *))block
{
    RKObjectLoader *loader = [self loaderForObject:object method:RKRequestMethodInvalid];
    loader.URL = [self.baseURL URLByAppendingResourcePath:resourcePath];
    // Yield to the block for setup
    block(loader);

    [loader send];
}

- (void)sendObject:(id<NSObject>)object method:(RKRequestMethod)method usingBlock:(void(^)(RKObjectLoader *))block
{
    RKObjectLoader *loader = [self loaderForObject:object method:method];
    // Yield to the block for setup
    block(loader);

    [loader send];
}

- (void)getObject:(id<NSObject>)object usingBlock:(void(^)(RKObjectLoader *))block
{
    [self sendObject:object method:RKRequestMethodGET usingBlock:block];
}

- (void)postObject:(id<NSObject>)object usingBlock:(void(^)(RKObjectLoader *))block
{
    [self sendObject:object method:RKRequestMethodPOST usingBlock:block];
}

- (void)putObject:(id<NSObject>)object usingBlock:(void(^)(RKObjectLoader *))block
{
    [self sendObject:object method:RKRequestMethodPUT usingBlock:block];
}

- (void)deleteObject:(id<NSObject>)object usingBlock:(void(^)(RKObjectLoader *))block
{
    [self sendObject:object method:RKRequestMethodDELETE usingBlock:block];
}

- (void)loadRelationship:(NSString *)relationshipName ofObject:(id)object usingBlock:(void(^)(RKObjectLoader *))block
{
    // TODO: Try to pull the path/url off of the object (relationshipResourcePath | relationshipURL)
    RKURL *URL = [self.router URLForRelationship:relationshipName ofObject:object method:RKRequestMethodGET];
    [self loadObjectsAtResourcePath:URL.resourcePath usingBlock:block];
}

#endif // NS_BLOCKS_AVAILABLE

#pragma mark - Object Instance Loaders for Non-nested JSON

- (void)getObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping *)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate
{
    [self sendObject:object method:RKRequestMethodGET usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = delegate;
        loader.objectMapping = objectMapping;
    }];
}

- (void)postObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping *)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate
{
    [self sendObject:object method:RKRequestMethodPOST usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = delegate;
        loader.objectMapping = objectMapping;
    }];
}

- (void)putObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping *)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate
{
    [self sendObject:object method:RKRequestMethodPUT usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = delegate;
        loader.objectMapping = objectMapping;
    }];
}

- (void)deleteObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping *)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate
{
    [self sendObject:object method:RKRequestMethodDELETE usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = delegate;
        loader.objectMapping = objectMapping;
    }];
}

- (RKRequestCache *)requestCache
{
    return self.client.requestCache;
}

- (RKRequestQueue *)requestQueue
{
    return self.client.requestQueue;
}

- (RKRouter *)router
{
    return self.client.router;
}

- (void)setRouter:(RKRouter *)router
{
    self.client.router = router;
}

#pragma mark - RKConfigrationDelegate

- (void)configureRequest:(RKRequest *)request
{
    [self.client configureRequest:request];
}

- (void)configureObjectLoader:(RKObjectLoader *)objectLoader
{
    objectLoader.serializationMIMEType = self.serializationMIMEType;
    [self configureRequest:objectLoader];
}

#pragma mark - Deprecations

+ (RKObjectManager *)objectManagerWithBaseURLString:(NSString *)baseURLString
{
    return [self managerWithBaseURLString:baseURLString];
}

+ (RKObjectManager *)objectManagerWithBaseURL:(NSURL *)baseURL
{
    return [self managerWithBaseURL:baseURL];
}

- (RKObjectLoader *)objectLoaderWithResourcePath:(NSString *)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate
{
    RKObjectLoader *loader = [self loaderWithResourcePath:resourcePath];
    loader.delegate = delegate;

    return loader;
}

- (RKObjectLoader *)objectLoaderForObject:(id<NSObject>)object method:(RKRequestMethod)method delegate:(id<RKObjectLoaderDelegate>)delegate
{
    RKObjectLoader *loader = [self loaderForObject:object method:method];
    loader.delegate = delegate;
    return loader;
}

- (void)loadObjectsAtResourcePath:(NSString *)resourcePath objectMapping:(RKObjectMapping *)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate
{
    RKObjectLoader *loader = [self loaderWithResourcePath:resourcePath];
    loader.delegate = delegate;
    loader.method = RKRequestMethodGET;
    loader.objectMapping = objectMapping;

    [loader send];
}

- (RKManagedObjectStore *)objectStore
{
    return self.managedObjectStore;
}

- (void)setObjectStore:(RKManagedObjectStore *)objectStore
{
    self.managedObjectStore = objectStore;
}

@end
