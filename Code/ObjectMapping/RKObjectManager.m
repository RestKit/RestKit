//
//  RKObjectManager.m
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKObjectManager.h"
#import "RKObjectSerializer.h"
#import "../CoreData/RKManagedObjectStore.h"
#import "../CoreData/RKManagedObjectLoader.h"
//#import "../Support/RKMIMETypes.h"
#import "../Support/Support.h"
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

- (id)initWithBaseURL:(NSString*)baseURL {
    self = [super init];
	if (self) {
        _mappingProvider = [RKObjectMappingProvider new];
		_router = [RKObjectRouter new];
		_client = [[RKClient clientWithBaseURL:baseURL] retain];
        _onlineState = RKObjectManagerOnlineStateUndetermined;
        
        self.acceptMIMEType = RKMIMETypeJSON;
        self.serializationMIMEType = RKMIMETypeFormURLEncoded;
        
        // Setup default error message mappings
        RKObjectMapping* errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
        [errorMapping mapKeyPath:@"" toAttribute:@"errorMessage"];
        [_mappingProvider setMapping:errorMapping forKeyPath:@"error"];
        [_mappingProvider setMapping:errorMapping forKeyPath:@"errors"];
        		
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

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams delegate:(id<RKObjectLoaderDelegate>)delegate {
	NSString* resourcePathWithQuery = RKPathAppendQueryParams(resourcePath, queryParams);
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePathWithQuery delegate:delegate];
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

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams objectMapping:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate {
	NSString* resourcePathWithQuery = RKPathAppendQueryParams(resourcePath, queryParams);
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePathWithQuery delegate:delegate];
	loader.method = RKRequestMethodGET;
	loader.objectMapping = objectMapping;

	[loader send];

	return loader;
}

/////////////////////////////////////////////////////////////
#pragma mark - Object Instance Loaders

- (RKObjectLoader*)objectLoaderForObject:(id<NSObject>)object method:(RKRequestMethod)method delegate:(id<RKObjectLoaderDelegate>)delegate {
	NSString* resourcePath = [self.router resourcePathForObject:object method:method];    
    RKObjectMapping* serializationMapping = [self.mappingProvider serializationMappingForClass:[object class]];
    RKObjectSerializer* serializer = [RKObjectSerializer serializerWithObject:object mapping:serializationMapping];
    NSError* error = nil;
    id params = [serializer serializationForMIMEType:self.serializationMIMEType error:&error];    
	RKObjectLoader* loader = [self objectLoaderWithResourcePath:resourcePath delegate:delegate];
    
    if (error) {
        [delegate objectLoader:loader didFailWithError:error];
        return nil;
    }

	loader.method = method;
	loader.params = params;
	loader.targetObject = object;

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

@end
