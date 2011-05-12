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
// TODO: introducing a new dependency?
#import "RKJSONParser.h"

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

- (id)initWithBaseURL:(NSString*)baseURL {
    self = [super init];
	if (self) {
        _mappingProvider = [RKObjectMappingProvider new];
		_router = [RKDynamicRouter new];
		_client = [[RKClient clientWithBaseURL:baseURL] retain];
        
        // TODO: we may want to be able to set this later. jbe.
        [_client setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        _parsersForMIMETypes = [NSMutableDictionary new];
        RKJSONParser* jsonParser = [[RKJSONParser new] autorelease];
        [_parsersForMIMETypes setObject:jsonParser forKey:@"application/json"];
        
        self.serializationMIMEType = @"application/x-www-form-urlencoded";
        
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

+ (RKObjectManager*)objectManagerWithBaseURL:(NSString*)baseURL {
	RKObjectManager* manager = [[[RKObjectManager alloc] initWithBaseURL:baseURL] autorelease];
	if (nil == sharedManager) {
		[RKObjectManager setSharedManager:manager];
	}
	return manager;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_parsersForMIMETypes release];
    _parsersForMIMETypes = nil;
	[_router release];
	_router = nil;
	[_client release];
	_client = nil;
	[_objectStore release];
	_objectStore = nil;
    [_serializationMIMEType release];
    _serializationMIMEType = nil;
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

- (void)setParser:(id<RKParser>)parser forMIMEType:(NSString*)mimeType {
    [_parsersForMIMETypes setObject:parser forKey:mimeType];
}

- (id<RKParser>)parserForMIMEType:(NSString*)mimeType {
    return [_parsersForMIMETypes objectForKey:mimeType];
}

#pragma mark Object Loading

- (RKObjectLoader*)objectLoaderWithResourcePath:(NSString*)resourcePath delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
    RKObjectLoader* objectLoader = nil;
    
    // TODO: Can we eliminate and just use RKObjectLoader???
    Class managedObjectLoaderClass = NSClassFromString(@"RKManagedObjectLoader");
    if (self.objectStore && managedObjectLoaderClass) {
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
	NSString* resourcePathWithQuery = RKPathAppendQueryParams(resourcePath, queryParams);
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePathWithQuery delegate:delegate];
	loader.method = RKRequestMethodGET;

	[loader send];

	return loader;
}

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath objectClass:(Class<RKObjectMappable>)objectClass delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePath delegate:delegate];
	loader.method = RKRequestMethodGET;
//	loader.objectClass = objectClass;

	[loader send];

	return loader;
}

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams objectClass:(Class<RKObjectMappable>)objectClass delegate:(NSObject <RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePathWithQuery = RKPathAppendQueryParams(resourcePath, queryParams);
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePathWithQuery delegate:delegate];
	loader.method = RKRequestMethodGET;
//	loader.objectClass = objectClass;

	[loader send];

	return loader;
}

/////////////////////////////////////////////////////////////
// Object Instance Loaders

- (RKObjectLoader*)objectLoaderForObject:(NSObject<RKObjectMappable>*)object method:(RKRequestMethod)method delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	// Get the serialization representation from the router
	NSString* resourcePath = [self.router resourcePathForObject:object method:method];
    
    // TODO: Use the new serializer...
    RKObjectMapping* serializationMapping = [self.mappingProvider objectMappingForClass:[object class]];
    RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:object mapping:serializationMapping];
    NSError* error = nil;;
    id params = [serializer serializationForMIMEType:self.serializationMIMEType error:&error];
    
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePath delegate:delegate];
    
    if (error) {
        [delegate objectLoader:loader didFailWithError:error];
        // TODO: what do we return here so the request doesn't get sent?
        return nil;
    }

	loader.method = method;
	loader.params = params;
	loader.targetObject = object;

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
