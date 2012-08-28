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
#import "Support.h"

NSString * const RKObjectManagerDidBecomeOfflineNotification = @"RKDidEnterOfflineModeNotification";
NSString * const RKObjectManagerDidBecomeOnlineNotification = @"RKDidEnterOnlineModeNotification";

//////////////////////////////////
// Shared Instances

static RKObjectManager  *sharedManager = nil;
static NSOperationQueue *defaultMappingQueue = nil;

///////////////////////////////////

@implementation RKObjectManager

@synthesize managedObjectStore = _managedObjectStore;
@synthesize serializationMIMEType = _serializationMIMEType;
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
        defaultMappingQueue = nil;
    }

    if (newDefaultMappingQueue) {
        defaultMappingQueue = newDefaultMappingQueue;
    }
}

- (id)init
{
    self = [super init];
    if (self) {
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
    sharedManager = manager;
}

+ (RKObjectManager *)managerWithBaseURLString:(NSString *)baseURLString
{
    return [self managerWithBaseURL:[RKURL URLWithString:baseURLString]];
}

+ (RKObjectManager *)managerWithBaseURL:(NSURL *)baseURL
{
    RKObjectManager *manager = [[self alloc] initWithBaseURL:[RKURL URLWithBaseURL:baseURL]];
    return manager;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"client.reachabilityObserver"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"client.reachabilityObserver"]) {
        [self reachabilityObserverDidChange:change];
    }
}

- (void)reachabilityObserverDidChange:(NSDictionary *)change
{
//    RKReachabilityObserver *oldReachabilityObserver = [change objectForKey:NSKeyValueChangeOldKey];
//    RKReachabilityObserver *newReachabilityObserver = [change objectForKey:NSKeyValueChangeNewKey];
//
//    if (! [oldReachabilityObserver isEqual:[NSNull null]]) {
//        RKLogDebug(@"Reachability observer changed for RKClient %@ of RKObjectManager %@, stopping observing reachability changes", self.client, self);
//        [[NSNotificationCenter defaultCenter] removeObserver:self name:RKReachabilityDidChangeNotification object:oldReachabilityObserver];
//    }
//
//    if (! [newReachabilityObserver isEqual:[NSNull null]]) {
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(reachabilityChanged:)
//                                                     name:RKReachabilityDidChangeNotification
//                                                   object:newReachabilityObserver];
//
//        RKLogDebug(@"Reachability observer changed for client %@ of object manager %@, starting observing reachability changes", self.client, self);
//    }
//
//    // Initialize current Network Status
//    if ([self.client.reachabilityObserver isReachabilityDetermined]) {
//        BOOL isNetworkReachable = [self.client.reachabilityObserver isNetworkReachable];
//        self.networkStatus = isNetworkReachable ? RKObjectManagerNetworkStatusOnline : RKObjectManagerNetworkStatusOffline;
//    } else {
//        self.networkStatus = RKObjectManagerNetworkStatusUnknown;
//    }
}

- (void)reachabilityChanged:(NSNotification *)notification
{
//    BOOL isHostReachable = [self.client.reachabilityObserver isNetworkReachable];
//
//    _networkStatus = isHostReachable ? RKObjectManagerNetworkStatusOnline : RKObjectManagerNetworkStatusOffline;
//
//    if (isHostReachable) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOnlineNotification object:self];
//    } else {
//        [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:self];
//    }
}

- (void)setAcceptMIMEType:(NSString *)MIMEType
{
//    [self.client setValue:MIMEType forHTTPHeaderField:@"Accept"];
}

- (NSString *)acceptMIMEType
{
//    return [self.client.HTTPHeaders valueForKey:@"Accept"];
}

/////////////////////////////////////////////////////////////
#pragma mark - Object Collection Loaders

- (NSURL *)baseURL
{
//    return self.client.baseURL;
}

//- (RKObjectPaginator *)paginatorWithResourcePathPattern:(NSString *)resourcePathPattern
//{
//    RKURL *patternURL = [[self baseURL] URLByAppendingResourcePath:resourcePathPattern];
//    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL
//                                                              mappingProvider:self.mappingProvider];
//    paginator.configurationDelegate = self;
//    return paginator;
//}

@end
