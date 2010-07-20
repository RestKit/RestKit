//
//  RKResourceManager.m
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKResourceManager.h"

NSString* const RKDidEnterOfflineModeNotification = @"RKDidEnterOfflineModeNotification";
NSString* const RKDidEnterOnlineModeNotification = @"RKDidEnterOnlineModeNotification";

//////////////////////////////////
// Global Instance

static RKResourceManager* sharedManager = nil;

///////////////////////////////////

@implementation RKResourceManager

@synthesize mapper = _mapper;
@synthesize client = _client;
@synthesize objectStore = _objectStore;
@synthesize format = _format;
@synthesize router = _router;

- (id)initWithBaseURL:(NSString*)baseURL {
	if (self = [super init]) {
		_mapper = [[RKResourceMapper alloc] init];
		_router = [[RKStaticRouter alloc] init];
		_client = [[RKClient clientWithBaseURL:baseURL] retain];
		self.format = RKMappingFormatJSON;
		_isOnline = YES;		
	}
	return self;
}

+ (RKResourceManager*)manager {
	return sharedManager;
}

+ (void)setManager:(RKResourceManager*)manager {
	[sharedManager release];
	sharedManager = [manager retain];
}

+ (RKResourceManager*)managerWithBaseURL:(NSString*)baseURL {
	RKResourceManager* manager = [[[RKResourceManager alloc] initWithBaseURL:baseURL] autorelease];
	if (sharedManager == nil) {
		[RKResourceManager setManager:manager];
	}
	return manager;
}

- (void)dealloc {
	[_mapper release];
	[_router release];
	[_client release];
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

- (void)registerClass:(Class<RKResourceMappable>)class forElementNamed:(NSString*)elementName {
	[_mapper registerClass:class forElementNamed:elementName];
}

/////////////////////////////////////////////////////////////
// Model Collection Loaders

- (RKRequest*)loadResource:(NSString*)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(NSObject<RKResourceLoaderDelegate>*)delegate {
	return [self loadResource:resourcePath fetchRequest:nil method:method params:params delegate:delegate];
}

- (RKRequest*)loadResource:(NSString*)resourcePath delegate:(NSObject<RKResourceLoaderDelegate>*)delegate {
	return [self loadResource:resourcePath fetchRequest:nil method:RKRequestMethodGET params:nil delegate:delegate];
}

- (RKRequest*)loadResource:(NSString*)resourcePath method:(RKRequestMethod)method delegate:(NSObject<RKResourceLoaderDelegate>*)delegate {
	return [self loadResource:resourcePath fetchRequest:nil method:method params:nil delegate:delegate];
}

- (RKRequest*)loadResource:(NSString*)resourcePath params:(NSDictionary*)params delegate:(NSObject<RKResourceLoaderDelegate>*)delegate {
	return [self loadResource:resourcePath fetchRequest:nil method:RKRequestMethodGET params:params delegate:delegate];
}

- (RKRequest*)loadResource:(NSString*)resourcePath fetchRequest:(NSFetchRequest*)fetchRequest method:(RKRequestMethod)method delegate:(NSObject<RKResourceLoaderDelegate>*)delegate {
	return [self loadResource:resourcePath fetchRequest:fetchRequest method:method params:nil delegate:delegate];
}

- (RKRequest*)loadResource:(NSString*)resourcePath fetchRequest:(NSFetchRequest*)fetchRequest method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(NSObject<RKResourceLoaderDelegate>*)delegate {
	if ([self isOffline]) {
		return nil;
	}
	
	RKResourceLoader* loader = [RKResourceLoader loaderWithMapper:self.mapper];
	loader.fetchRequest = fetchRequest;
	loader.delegate = delegate;
	
	return [_client load:resourcePath method:method params:params delegate:loader callback:loader.callback];	
}

/////////////////////////////////////////////////////////////
// Model Instance Loaders

- (RKRequest*)resourceLoaderRequest:(id<RKResourceMappable>)model resourcePath:(NSString*)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(NSObject<RKResourceLoaderDelegate>*)delegate {
	if (method != RKRequestMethodGET) {
		NSError* error = [self.objectStore save];
		if (error != nil) {
			NSLog(@"[RestKit] RKModelManager: Error saving managed object context before PUT/POST/DELETE: error=%@ userInfo=%@", error, error.userInfo);
		}
	}
	
	RKRequest* request = [self loadResource:resourcePath method:method params:params delegate:delegate];
	request.userData = model;
	return request;
}

- (RKRequest*)getObject:(NSObject<RKResourceMappable>*)object delegate:(NSObject<RKResourceLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodGET];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodGET];
	return [self resourceLoaderRequest:object resourcePath:resourcePath method:RKRequestMethodGET params:params delegate:delegate];
}

- (RKRequest*)postObject:(NSObject<RKResourceMappable>*)object delegate:(NSObject<RKResourceLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodPOST];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodPOST];
	return [self resourceLoaderRequest:object resourcePath:resourcePath method:RKRequestMethodPOST params:params delegate:delegate];
}

- (RKRequest*)putObject:(NSObject<RKResourceMappable>*)object delegate:(NSObject<RKResourceLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodPUT];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodPUT];
	return [self resourceLoaderRequest:object resourcePath:resourcePath method:RKRequestMethodPUT params:params delegate:delegate];
}

- (RKRequest*)deleteObject:(NSObject<RKResourceMappable>*)object delegate:(NSObject<RKResourceLoaderDelegate>*)delegate {
	NSString* resourcePath = [_router pathForObject:object method:RKRequestMethodDELETE];
	NSObject<RKRequestSerializable>* params = [_router serializationForObject:object method:RKRequestMethodDELETE];
	return [self resourceLoaderRequest:object resourcePath:resourcePath method:RKRequestMethodDELETE params:params delegate:delegate];
}

@end
