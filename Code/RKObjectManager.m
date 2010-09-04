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

static RKObjectManager* sharedManager = nil;

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

+ (RKObjectManager*)manager {
	return sharedManager;
}

+ (void)setManager:(RKObjectManager*)manager {
	[sharedManager release];
	sharedManager = [manager retain];
}

+ (RKObjectManager*)managerWithBaseURL:(NSString*)baseURL {
	RKObjectManager* manager = [[[RKObjectManager alloc] initWithBaseURL:baseURL] autorelease];
	if (sharedManager == nil) {
		[RKObjectManager setManager:manager];
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

#pragma mark Model Methods

- (void)registerClass:(Class<RKObjectMappable>)class forElementNamed:(NSString*)elementName {
	[_mapper registerClass:class forElementNamed:elementName];
}

- (RKRequest*)requestWithResourcePath:(NSString*)resourcePath delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	if ([self isOffline]) {
		return nil;
	}
	
	RKObjectLoader* loader = [RKObjectLoader loaderWithMapper:self.mapper];
	loader.delegate = delegate;
	
	return [self.client requestWithResourcePath:resourcePath delegate:loader callback:loader.callback];
}

/////////////////////////////////////////////////////////////
// Model Collection Loaders

- (RKRequest*)getObjectsAtResourcePath:(NSString*)resourcePath delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	RKRequest* request = [self requestWithResourcePath:resourcePath delegate:delegate];
	request.method = RKRequestMethodGET;	
	[request send];
	
	return request;
}

- (RKRequest*)getObjectsAtResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams delegate:(NSObject <RKObjectLoaderDelegate>*)delegate {
	return [self getObjectsAtResourcePath:[self.client resourcePath:resourcePath withQueryParams:queryParams] delegate:delegate];
}

/////////////////////////////////////////////////////////////
// Model Instance Loaders

- (RKRequest*)requestForObject:(id<RKObjectMappable>)object resourcePath:(NSString*)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	// TODO: Need to factor core data stuff out of here...
	if (method != RKRequestMethodGET) {
		NSError* error = [self.objectStore save];
		if (error != nil) {
			NSLog(@"[RestKit] RKModelManager: Error saving managed object context before PUT/POST/DELETE: error=%@ userInfo=%@", error, error.userInfo);
		}
	}
	
	RKRequest* request = [self requestWithResourcePath:resourcePath delegate:delegate];
	request.method = method;
	request.params = params;
	request.userData = object;
	
	return request;
}

- (RKRequest*)getObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodGET];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodGET];
	return [self requestForObject:object resourcePath:resourcePath method:RKRequestMethodGET params:params delegate:delegate];
}

- (RKRequest*)postObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodPOST];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodPOST];
	return [self requestForObject:object resourcePath:resourcePath method:RKRequestMethodPOST params:params delegate:delegate];
}

- (RKRequest*)putObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodPUT];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodPUT];
	return [self requestForObject:object resourcePath:resourcePath method:RKRequestMethodPUT params:params delegate:delegate];
}

- (RKRequest*)deleteObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodDELETE];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodDELETE];
	return [self requestForObject:object resourcePath:resourcePath method:RKRequestMethodDELETE params:params delegate:delegate];
}

@end
