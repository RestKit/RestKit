//
//  RKObjectManager.m
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKObjectManager.h"

NSString* const RKDidEnterOfflineModeNotification = @"RKDidEnterOfflineModeNotification";
NSString* const RKDidEnterOnlineModeNotification = @"RKDidEnterOnlineModeNotification";

//////////////////////////////////
// Global Instance

static RKObjectManager* globalManager = nil;

///////////////////////////////////

@implementation RKObjectManager

@synthesize mapper = _mapper;
@synthesize client = _client;
@synthesize objectStore = _objectStore;
@synthesize format = _format;
@synthesize router = _router;

- (id)initWithBaseURL:(NSString*)baseURL {
	if (self = [super init]) {
		_mapper = [[RKObjectMapper alloc] init];
		_router = [[RKStaticRouter alloc] init];
		_client = [[RKClient clientWithBaseURL:baseURL] retain];
		self.format = RKMappingFormatJSON;
		_isOnline = YES;		
	}
	return self;
}

+ (RKObjectManager*)globalManager {
	return globalManager;
}

+ (void)setGlobalManager:(RKObjectManager*)manager {
	[manager retain];
	[globalManager release];
	globalManager = manager;
}

+ (RKObjectManager*)objectManagerWithBaseURL:(NSString*)baseURL {
	RKObjectManager* manager = [[[RKObjectManager alloc] initWithBaseURL:baseURL] autorelease];
	if (nil == globalManager) {
		[RKObjectManager setGlobalManager:manager];
	}
	return manager;
}

- (void)dealloc {
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

- (void)goOffline {
	_isOnline = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:RKDidEnterOfflineModeNotification object:self];
}

- (void)goOnline {
	_isOnline = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:RKDidEnterOnlineModeNotification object:self];
}

- (BOOL)isOnline {
	return _isOnline;
}

- (BOOL)isOffline {
	return ![self isOnline];
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

- (RKObjectLoader*)loaderWithResourcePath:(NSString*)resourcePath objectClass:(Class<RKObjectMappable>)objectClass delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	if ([self isOffline]) {
		return nil;
	}
	
	// Grab request through client to get HTTP AUTH & Headers
	RKRequest* request = [self.client requestWithResourcePath:resourcePath delegate:nil callback:nil];
	RKObjectLoader* loader = [RKObjectLoader loaderWithMapper:self.mapper request:request delegate:delegate];
	loader.objectClass = objectClass;
	
	return loader;
}

/////////////////////////////////////////////////////////////
// Object Collection Loaders

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	RKObjectLoader* loader = [self loaderWithResourcePath:resourcePath objectClass:nil delegate:delegate];
	loader.method = RKRequestMethodGET;
	
	[loader send];
	
	return loader;
}

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams delegate:(NSObject <RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePathWithQuery = [self.client resourcePath:resourcePath withQueryParams:queryParams];
	RKObjectLoader* loader = [self loaderWithResourcePath:resourcePathWithQuery objectClass:nil delegate:delegate];
	loader.method = RKRequestMethodGET;	
	
	[loader send];
	
	return loader;
}

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath objectClass:(Class<RKObjectMappable>)objectClass delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	RKObjectLoader* loader = [self loaderWithResourcePath:resourcePath objectClass:objectClass delegate:delegate];
	loader.method = RKRequestMethodGET;
	
	[loader send];
	
	return loader;
}

- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams objectClass:(Class<RKObjectMappable>)objectClass delegate:(NSObject <RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePathWithQuery = [self.client resourcePath:resourcePath withQueryParams:queryParams];
	RKObjectLoader* loader = [self loaderWithResourcePath:resourcePathWithQuery objectClass:objectClass delegate:delegate];
	loader.method = RKRequestMethodGET;	
	
	[loader send];
	
	return loader;
}

/////////////////////////////////////////////////////////////
// Object Instance Loaders

- (RKObjectLoader*)loaderForObject:(NSObject<RKObjectMappable>*)object resourcePath:(NSString*)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	// TODO: Need to factor core data stuff out of here...
	if (method != RKRequestMethodGET) {
		NSError* error = [self.objectStore save];
		if (error != nil) {
			NSLog(@"[RestKit] RKModelManager: Error saving managed object context before PUT/POST/DELETE: error=%@ userInfo=%@", error, error.userInfo);
		}
	}
	
	RKObjectLoader* loader = [self loaderWithResourcePath:resourcePath objectClass:[object class] delegate:delegate];
	loader.method = method;
	loader.params = params;
	loader.source = object;
	loader.managedObjectStore = self.objectStore;
	
	return loader;
}

- (RKObjectLoader*)getObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodGET];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodGET];
	return [self loaderForObject:object resourcePath:resourcePath method:RKRequestMethodGET params:params delegate:delegate];
}

- (RKObjectLoader*)postObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodPOST];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodPOST];
	return [self loaderForObject:object resourcePath:resourcePath method:RKRequestMethodPOST params:params delegate:delegate];
}

- (RKObjectLoader*)putObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodPUT];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodPUT];
	return [self loaderForObject:object resourcePath:resourcePath method:RKRequestMethodPUT params:params delegate:delegate];
}

- (RKObjectLoader*)deleteObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodDELETE];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodDELETE];
	return [self loaderForObject:object resourcePath:resourcePath method:RKRequestMethodDELETE params:params delegate:delegate];
}

@end
