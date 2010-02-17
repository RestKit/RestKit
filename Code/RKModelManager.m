//
//  RKModelManager.m
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKModelManager.h"
#import "RKModelLoader.h"

NSString* const kRKDidEnterOfflineMode = @"kRKDidEnterOfflineMode";
NSString* const kRKDidEnterOnlineMode = @"kRKDidEnterOnlineMode";

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
		self.format = RKMappingFormatXML;
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
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKDidEnterOfflineMode object:[RKModelManager manager]];
}

- (void)goOnline {
	_isOnline = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKDidEnterOnlineMode object:[RKModelManager manager]];
}

- (BOOL)isOnline {
	return _isOnline;
}

- (BOOL)isOffline {
	return ![self isOnline];
}

- (void)setFormat:(RKMappingFormat)format {
	_format = format;
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
 
/**
 * Load a model from a restful resource and invoke the callback
 */
- (RKRequest*)loadModel:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	if ([self isOffline]) {
		return nil;
	}
	RKModelLoader* loader = [[RKModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	return [_client get:resourcePath delegate:loader callback:loader.memberCallback];
}

/**
 * Load a collection of models from a restful resource and invoke the callback
 */
- (RKRequest*)loadModels:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	if ([self isOffline]) {
		return nil;
	}
	RKModelLoader* loader = [[RKModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	return [_client get:resourcePath delegate:loader callback:loader.collectionCallback];
}

- (RKRequest*)loadModels:(NSString*)resourcePath params:(NSDictionary*)params delegate:(id)delegate callback:(SEL)callback {
	if ([self isOffline]) {
		return nil;
	}
	RKModelLoader* loader = [[RKModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	return [_client get:resourcePath params:params delegate:loader callback:loader.collectionCallback];
}

- (RKRequest*)getModel:(id<RKModelMappable>)model delegate:(id)delegate callback:(SEL)callback {
	if ([self isOffline]) {
		return nil;
	}
	RKModelLoader* loader = [[RKModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	RKRequest* request = [_client get:[model memberPath] delegate:loader callback:loader.memberCallback];
	request.userData = model;
	return request;
}

- (RKRequest*)postModel:(id<RKModelMappable>)model delegate:(id)delegate callback:(SEL)callback {
	if ([self isOffline]) {
		return nil;
	}
	RKModelLoader* loader = [[RKModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	RKParams* params = [RKParams paramsWithDictionary:[model resourceParams]];
	RKRequest* request = [_client post:[model collectionPath] params:params delegate:loader callback:loader.memberCallback];
	request.userData = model;
	return request;
}

- (RKRequest*)putModel:(id<RKModelMappable>)model delegate:(id)delegate callback:(SEL)callback {
	if ([self isOffline]) {
		return nil;
	}
	RKModelLoader* loader = [[RKModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	RKParams* params = [RKParams paramsWithDictionary:[model resourceParams]];
	RKRequest* request = [_client put:[model memberPath] params:params delegate:loader callback:loader.memberCallback];
	request.userData = model;
	return request;
}

- (RKRequest*)deleteModel:(id<RKModelMappable>)model delegate:(id)delegate callback:(SEL)callback {
	if ([self isOffline]) {
		return nil;
	}
	// TODO: are we responsible for deleting the object too,
	//		or are we to assume that the caller has/will delete it?
	RKRequest* request = [_client delete:[model memberPath] delegate:delegate callback:callback];
	request.userData = model;
	return request;
}

@end
