//
//  RKModelManager.m
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKModelManager.h"

NSString* const RKDidEnterOfflineModeNotification = @"RKDidEnterOfflineModeNotification";
NSString* const RKDidEnterOnlineModeNotification = @"RKDidEnterOnlineModeNotification";

//////////////////////////////////
// Global Instance

static RKModelManager* sharedManager = nil;

///////////////////////////////////

@implementation RKModelManager

@synthesize mapper = _mapper;
@synthesize client = _client;
@synthesize objectStore = _objectStore;
@synthesize format = _format;

- (id)initWithBaseURL:(NSString*)baseURL {
	if (self = [super init]) {
		_mapper = [[RKModelMapper alloc] init];
		_client = [[RKClient clientWithBaseURL:baseURL] retain];
		self.format = RKMappingFormatJSON;
		_isOnline = YES;
	}
	return self;
}

+ (RKModelManager*)manager {
	return sharedManager;
}

+ (void)setManager:(RKModelManager*)manager {
	[sharedManager release];
	sharedManager = [manager retain];
}

+ (RKModelManager*)managerWithBaseURL:(NSString*)baseURL {
	RKModelManager* manager = [[[RKModelManager alloc] initWithBaseURL:baseURL] autorelease];
	if (sharedManager == nil) {
		[RKModelManager setManager:manager];
	}
	return manager;
}

- (void)dealloc {
	[_mapper release];
	[_client release];
	[super dealloc];
}

- (void)goOffline {
	_isOnline = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:RKDidEnterOfflineModeNotification object:[RKModelManager manager]];
}

- (void)goOnline {
	_isOnline = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:RKDidEnterOnlineModeNotification object:[RKModelManager manager]];
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

- (void)registerModel:(Class<RKModelMappable>)class forElementNamed:(NSString*)elementName {
	[_mapper registerModel:class forElementNamed:elementName];
}

/////////////////////////////////////////////////////////////
// Model Collection Loaders

- (RKRequest*)loadModels:(NSString *)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(NSObject<RKModelLoaderDelegate>*)delegate {
	if ([self isOffline]) {
		return nil;
	}
	RKModelLoader* loader = [RKModelLoader loaderWithMapper:self.mapper];
	loader.delegate = delegate;
	
	return [_client load:resourcePath method:method params:params delegate:loader callback:loader.callback];
}

- (RKRequest*)loadModels:(NSString*)resourcePath delegate:(NSObject<RKModelLoaderDelegate>*)delegate {
	return [self loadModels:resourcePath method:RKRequestMethodGET params:nil delegate:delegate];
}

- (RKRequest*)loadModels:(NSString*)resourcePath method:(RKRequestMethod)method delegate:(NSObject<RKModelLoaderDelegate>*)delegate {
	return [self loadModels:resourcePath method:method params:nil delegate:delegate];
}

- (RKRequest*)loadModels:(NSString*)resourcePath params:(NSDictionary*)params delegate:(NSObject<RKModelLoaderDelegate>*)delegate {
	return [self loadModels:resourcePath method:RKRequestMethodGET params:params delegate:delegate];
}

/////////////////////////////////////////////////////////////
// Model Instance Loaders

- (RKRequest*)modelLoaderRequest:(id<RKModelMappable>)model resourcePath:(NSString*)resourcePath method:(RKRequestMethod)method params:(RKParams*)params delegate:(NSObject<RKModelLoaderDelegate>*)delegate {
	RKRequest* request = [self loadModels:resourcePath method:method params:params delegate:delegate];
	request.userData = model;
	return request;
}

- (RKRequest*)getModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate {
	return [self modelLoaderRequest:model resourcePath:[model memberPath] method:RKRequestMethodGET params:nil delegate:delegate];
}

- (RKRequest*)postModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate {
	RKParams* params = [RKParams paramsWithDictionary:[model resourceParams]];
	return [self modelLoaderRequest:model resourcePath:[model collectionPath] method:RKRequestMethodPOST params:params delegate:delegate];
}

- (RKRequest*)putModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate {
	RKParams* params = [RKParams paramsWithDictionary:[model resourceParams]];
	return [self modelLoaderRequest:model resourcePath:[model memberPath] method:RKRequestMethodPUT params:params delegate:delegate];
}

- (RKRequest*)deleteModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate {
	return [self modelLoaderRequest:model resourcePath:[model memberPath] method:RKRequestMethodDELETE params:nil delegate:delegate];
}

@end
