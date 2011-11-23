//
//  RKObjectManager.m
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters
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
#import "RKErrorMessage.h"

NSString* const RKDidEnterOfflineModeNotification = @"RKDidEnterOfflineModeNotification";
NSString* const RKDidEnterOnlineModeNotification = @"RKDidEnterOnlineModeNotification";

//////////////////////////////////
// Shared Instance

static RKObjectManager* sharedManager = nil;

///////////////////////////////////

@implementation RKObjectManager

@synthesize client = _client;
@synthesize objectStore = _objectStore;
@synthesize router = _router;
@synthesize mappingProvider = _mappingProvider;
@synthesize serializationMIMEType = _serializationMIMEType;
@synthesize inferMappingsFromObjectTypes = _inferMappingsFromObjectTypes;

- (id)initWithBaseURL:(NSString*)baseURL {
    self = [super init];
	if (self) {
        _mappingProvider = [RKObjectMappingProvider new];
		_router = [RKObjectRouter new];
		_client = [[RKClient clientWithBaseURL:baseURL] retain];
        _onlineState = RKObjectManagerOnlineStateUndetermined;
        _inferMappingsFromObjectTypes = NO;
        
        self.acceptMIMEType = RKMIMETypeJSON;
        self.serializationMIMEType = RKMIMETypeFormURLEncoded;
        
        // Setup default error message mappings
        RKObjectMapping* errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
        [errorMapping mapKeyPath:@"" toAttribute:@"errorMessage"];
        [_mappingProvider setMapping:errorMapping forKeyPath:@"error"];
        [_mappingProvider setMapping:errorMapping forKeyPath:@"errors"];
        		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reachabilityChanged:)
													 name:RKReachabilityDidChangeNotification
												   object:_client.reachabilityObserver];
	}
    
	return self;
}

+ (RKObjectManager*)sharedManager {
	return sharedManager;
}

+ (void)setSharedManager:(RKObjectManager*)manager {
	[manager retain];
	[sharedManager release];
	sharedManager = manager;
}

+ (RKObjectManager*)objectManagerWithBaseURL:(NSString*)baseURL {
	RKObjectManager* manager = [[[self alloc] initWithBaseURL:baseURL] autorelease];
	if (nil == sharedManager) {
		[RKObjectManager setSharedManager:manager];
	}
	return manager;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[_router release];
	_router = nil;
	[_client release];
	_client = nil;
	[_objectStore release];
	_objectStore = nil;
    [_serializationMIMEType release];
    _serializationMIMEType = nil;
    [_mappingProvider release];
    _mappingProvider = nil;
    
	[super dealloc];
}

- (BOOL)isOnline {
	return (_onlineState == RKObjectManagerOnlineStateConnected);
}

- (BOOL)isOffline {
	return ![self isOnline];
}

- (void)reachabilityChanged:(NSNotification*)notification {
	BOOL isHostReachable = [self.client.reachabilityObserver isNetworkReachable];

	_onlineState = isHostReachable ? RKObjectManagerOnlineStateConnected : RKObjectManagerOnlineStateDisconnected;

	if (isHostReachable) {
		[[NSNotificationCenter defaultCenter] postNotificationName:RKDidEnterOnlineModeNotification object:self];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:RKDidEnterOfflineModeNotification object:self];
	}
}

- (void)setAcceptMIMEType:(NSString*)MIMEType {
    [_client setValue:MIMEType forHTTPHeaderField:@"Accept"];
}

- (NSString*)acceptMIMEType {
    return [self.client.HTTPHeaders valueForKey:@"Accept"];
}

/////////////////////////////////////////////////////////////
#pragma mark - Object Collection Loaders

- (RKObjectLoader*)objectLoaderWithResourcePath:(NSString*)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate {
    RKObjectLoader* objectLoader = nil;
    Class managedObjectLoaderClass = NSClassFromString(@"RKManagedObjectLoader");
    if (self.objectStore && managedObjectLoaderClass) {
        objectLoader = [managedObjectLoaderClass loaderWithResourcePath:resourcePath objectManager:self delegate:delegate];
    } else {
        objectLoader = [RKObjectLoader loaderWithResourcePath:resourcePath objectManager:self delegate:delegate];
    }	
    
	return objectLoader;
}

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate {
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePath delegate:delegate];
	loader.method = RKRequestMethodGET;

	[loader send];

	return loader;
}

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath objectMapping:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate {
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePath delegate:delegate];
	loader.method = RKRequestMethodGET;
    loader.objectMapping = objectMapping;

	[loader send];

	return loader;
}

/////////////////////////////////////////////////////////////
#pragma mark - Object Instance Loaders

- (RKObjectLoader*)objectLoaderForObject:(id<NSObject>)object method:(RKRequestMethod)method delegate:(id<RKObjectLoaderDelegate>)delegate {
    NSString* resourcePath = [self.router resourcePathForObject:object method:method];
    RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePath delegate:delegate];
    loader.method = method;
    loader.sourceObject = object;
    loader.targetObject = object;
    loader.serializationMIMEType = self.serializationMIMEType;
    loader.serializationMapping = [self.mappingProvider serializationMappingForClass:[object class]];
    
    if (self.inferMappingsFromObjectTypes) {
        RKObjectMapping* objectMapping = [self.mappingProvider objectMappingForClass:[object class]];
        RKLogDebug(@"Auto-selected object mapping %@ for object of type %@", objectMapping, NSStringFromClass([object class]));
        loader.objectMapping = objectMapping;
    }

	return loader;
}

- (RKObjectLoader*)getObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodGET delegate:delegate];
	[loader send];
	return loader;
}

- (RKObjectLoader*)postObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodPOST delegate:delegate];
	[loader send];
	return loader;
}

- (RKObjectLoader*)putObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodPUT delegate:delegate];
	[loader send];
	return loader;
}

- (RKObjectLoader*)deleteObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodDELETE delegate:delegate];
	[loader send];
	return loader;
}

#if NS_BLOCKS_AVAILABLE

#pragma mark - Block Configured Object Loaders

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block {
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePath delegate:delegate];
	loader.method = RKRequestMethodGET;
    
    // Yield to the block for setup
    block(loader);
    
	[loader send];
    
	return loader;
}

- (RKObjectLoader*)sendObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block {
    RKObjectLoader* loader = [self objectLoaderWithResourcePath:nil delegate:delegate];
    loader.sourceObject = object;
    loader.targetObject = object;
    loader.serializationMIMEType = self.serializationMIMEType;
    loader.serializationMapping = [self.mappingProvider serializationMappingForClass:[object class]];
    
    // Yield to the block for setup
    block(loader);
    
    if (loader.resourcePath == nil) {
        loader.resourcePath = [self.router resourcePathForObject:object method:loader.method];
    }
    
    if (loader.objectMapping == nil) {
        if (self.inferMappingsFromObjectTypes) {
            RKObjectMapping* objectMapping = [self.mappingProvider objectMappingForClass:[object class]];
            RKLogDebug(@"Auto-selected object mapping %@ for object of type %@", objectMapping, NSStringFromClass([object class]));
            loader.objectMapping = objectMapping;
        }
    }
    
    [loader send];
    return loader;
}
                                                                                                        
- (RKObjectLoader*)sendObject:(id<NSObject>)object method:(RKRequestMethod)method delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block {
    return [self sendObject:object delegate:delegate block:^(RKObjectLoader* loader) {
        loader.method = method;
        block(loader);
    }];
}

- (RKObjectLoader*)getObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block {
    return [self sendObject:object method:RKRequestMethodGET delegate:delegate block:block];
}

- (RKObjectLoader*)postObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block {
    return [self sendObject:object method:RKRequestMethodPOST delegate:delegate block:block];
}

- (RKObjectLoader*)putObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block {
    return [self sendObject:object method:RKRequestMethodPUT delegate:delegate block:block];
}

- (RKObjectLoader*)deleteObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block {
    return [self sendObject:object method:RKRequestMethodDELETE delegate:delegate block:block];
}

#endif // NS_BLOCKS_AVAILABLE

#pragma mark - Object Instance Loaders for Non-nested JSON

- (RKObjectLoader*)getObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodGET delegate:delegate];
    if ([object isMemberOfClass:[objectMapping objectClass]]) {
        loader.targetObject = object;
    } else {
        loader.targetObject = nil;
    }
    loader.objectMapping = objectMapping;
	[loader send];
	return loader;
}

- (RKObjectLoader*)postObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodPOST delegate:delegate];
    if ([object isMemberOfClass:[objectMapping objectClass]]) {
        loader.targetObject = object;
    } else {
        loader.targetObject = nil;
    }
	loader.objectMapping = objectMapping;
    [loader send];
	return loader;
}

- (RKObjectLoader*)putObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodPUT delegate:delegate];
    if ([object isMemberOfClass:[objectMapping objectClass]]) {
        loader.targetObject = object;
    } else {
        loader.targetObject = nil;
    }
    loader.objectMapping = objectMapping;
	[loader send];
	return loader;
}

- (RKObjectLoader*)deleteObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodDELETE delegate:delegate];
    if ([object isMemberOfClass:[objectMapping objectClass]]) {
        loader.targetObject = object;
    } else {
        loader.targetObject = nil;
    }
    loader.objectMapping = objectMapping;
	[loader send];
	return loader;
}

- (RKRequestCache *)requestCache {
    return self.client.requestCache;
}

- (RKRequestQueue *)requestQueue {
    return self.client.requestQueue;
}

@end
