//
//  RKObjectManager.m
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKObjectManager.h"
#import "../CoreData/RKManagedObjectStore.h"
#import "../CoreData/RKManagedObjectLoader.h"

NSString* const RKDidEnterOfflineModeNotification = @"RKDidEnterOfflineModeNotification";
NSString* const RKDidEnterOnlineModeNotification = @"RKDidEnterOnlineModeNotification";

//////////////////////////////////
// Shared Instance

static RKObjectManager* sharedManager = nil;

///////////////////////////////////

@implementation RKObjectManager

@synthesize mapper = _mapper;
@synthesize client = _client;
@synthesize objectStore = _objectStore;
@synthesize format = _format;
@synthesize router = _router;

- (id)initWithBaseURL:(NSString*)baseURL {
	return self = [self initWithBaseURL:baseURL objectMapper:[[[RKObjectMapper alloc] init] autorelease] router:[[[RKDynamicRouter alloc] init] autorelease]];
}

- (id)initWithBaseURL:(NSString*)baseURL objectMapper:(RKObjectMapper*)mapper router:(NSObject<RKRouter>*)router {
    self = [super init];
	if (self) {
		_mapper = [mapper retain];
		_router = [router retain];
		_client = [[RKClient clientWithBaseURL:baseURL] retain];

		self.format = RKMappingFormatJSON;
		_onlineState = RKObjectManagerOnlineStateUndetermined;
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reachabilityChanged:)
													 name:RKReachabilityStateChangedNotification
												   object:nil];
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

// Deprecated
+ (RKObjectManager*)globalManager {
	return sharedManager;
}

// Deprecated
+ (void)setGlobalManager:(RKObjectManager*)manager {
	[manager retain];
	[sharedManager release];
	sharedManager = manager;
}

+ (RKObjectManager*)objectManagerWithBaseURL:(NSString*)baseURL objectMapper:(RKObjectMapper*)mapper router:(NSObject<RKRouter>*)router {
	RKObjectManager* manager = [[[RKObjectManager alloc] initWithBaseURL:baseURL objectMapper:mapper router:router] autorelease];
	if (nil == sharedManager) {
		[RKObjectManager setSharedManager:manager];
	}
	return manager;
}

+ (RKObjectManager*)objectManagerWithBaseURL:(NSString*)baseURL {
	RKObjectManager* manager = [[[RKObjectManager alloc] initWithBaseURL:baseURL] autorelease];
	if (nil == sharedManager) {
		[RKObjectManager setSharedManager:manager];
	}
	return manager;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_mapper release];
	_mapper = nil;
	[_router release];
	_router = nil;
	[_client release];
	_client = nil;
	[_objectStore release];
	_objectStore = nil;
	[super dealloc];
}

- (BOOL)isOnline {
	return (_onlineState == RKObjectManagerOnlineStateConnected);
}

- (BOOL)isOffline {
	return ![self isOnline];
}

- (void)reachabilityChanged:(NSNotification*)notification {
	BOOL isHostReachable = [self.client.baseURLReachabilityObserver isNetworkReachable];

	_onlineState = isHostReachable ? RKObjectManagerOnlineStateConnected : RKObjectManagerOnlineStateDisconnected;

	if (isHostReachable) {
		[[NSNotificationCenter defaultCenter] postNotificationName:RKDidEnterOnlineModeNotification object:self];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:RKDidEnterOfflineModeNotification object:self];
	}
}

- (void)setFormat:(RKMappingFormat)format {
	_format = format;
	_mapper.format = format;
	if (RKMappingFormatXML == _format) {
		[_client setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
	} else if (RKMappingFormatJSON == _format) {
		[_client setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	}
}

#pragma mark Object Loading

- (void)registerClass:(Class<RKObjectMappable>)class forElementNamed:(NSString*)elementName {
	[_mapper registerClass:class forElementNamed:elementName];
}

- (RKObjectLoader*)objectLoaderWithResourcePath:(NSString*)resourcePath delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
    RKObjectLoader* objectLoader = nil;
    
    Class managedObjectLoaderClass = NSClassFromString(@"RKManagedObjectLoader");
    if (managedObjectLoaderClass) {
        objectLoader = [managedObjectLoaderClass loaderWithResourcePath:resourcePath objectManager:self delegate:delegate];
    } else {
        objectLoader = [RKObjectLoader loaderWithResourcePath:resourcePath objectManager:self delegate:delegate];
    }	

	return objectLoader;
}

/////////////////////////////////////////////////////////////
// Object Collection Loaders

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePath delegate:delegate];
	loader.method = RKRequestMethodGET;

	[loader send];

	return loader;
}

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams delegate:(NSObject <RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePathWithQuery = [self.client resourcePath:resourcePath withQueryParams:queryParams];
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePathWithQuery delegate:delegate];
	loader.method = RKRequestMethodGET;

	[loader send];

	return loader;
}

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath objectClass:(Class<RKObjectMappable>)objectClass delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePath delegate:delegate];
	loader.method = RKRequestMethodGET;
	loader.objectClass = objectClass;

	[loader send];

	return loader;
}

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams objectClass:(Class<RKObjectMappable>)objectClass delegate:(NSObject <RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePathWithQuery = [self.client resourcePath:resourcePath withQueryParams:queryParams];
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePathWithQuery delegate:delegate];
	loader.method = RKRequestMethodGET;
	loader.objectClass = objectClass;

	[loader send];

	return loader;
}

/////////////////////////////////////////////////////////////
// Object Instance Loaders

- (RKObjectLoader*)objectLoaderForObject:(NSObject<RKObjectMappable>*)object method:(RKRequestMethod)method delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	// Get the serialization representation from the router
	NSString* resourcePath = [self.router resourcePathForObject:object method:method];
	NSObject<RKRequestSerializable>* params = [self.router serializationForObject:object method:method];

	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePath delegate:delegate];

	loader.method = method;
	loader.params = params;
	loader.targetObject = object;
	loader.objectClass = [object class];

	return loader;
}

- (RKObjectLoader*)getObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodGET delegate:delegate];
	[loader send];
	return loader;
}

- (RKObjectLoader*)postObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodPOST delegate:delegate];
	[loader send];
	return loader;
}

- (RKObjectLoader*)putObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodPUT delegate:delegate];
	[loader send];
	return loader;
}

- (RKObjectLoader*)deleteObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	RKObjectLoader* loader = [self objectLoaderForObject:object method:RKRequestMethodDELETE delegate:delegate];
	[loader send];
	return loader;
}

@end
