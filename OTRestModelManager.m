//
//  OTRestModelManager.m
//  OTRestFramework
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Objective3. All rights reserved.
//

#import "OTRestModelManager.h"
#import "OTRestModelLoader.h"

//////////////////////////////////
// Global Instance

static OTRestModelManager* sharedManager = nil;

///////////////////////////////////

@implementation OTRestModelManager

@synthesize mapper = _mapper;
@synthesize client = _client;
@synthesize objectStore = _objectStore;
@synthesize format = _format;

- (id)initWithBaseURL:(NSString*)baseURL {
	if (self = [super init]) {
		_mapper = [[OTRestModelMapper alloc] init];
		_client = [[OTRestClient clientWithBaseURL:baseURL] retain];
		self.format = OTRestMappingFormatXML;
	}
	return self;
}

+ (OTRestModelManager*)manager {
	return sharedManager;
}

+ (void)setManager:(OTRestModelManager*)manager {
	[sharedManager release];
	sharedManager = [manager retain];
}

+ (OTRestModelManager*)managerWithBaseURL:(NSString*)baseURL {
	OTRestModelManager* manager = [[[OTRestModelManager alloc] initWithBaseURL:baseURL] autorelease];
	if (sharedManager == nil) {
		[OTRestModelManager setManager:manager];
	}
	return manager;
}

- (void)dealloc {
	[_mapper release];
	[_client release];
	[super dealloc];
}

- (void)setFormat:(OTRestMappingFormat)format {
	_format = format;
	if (OTRestMappingFormatXML == _format) {
		[_client setValue:@"application/xml" forHTTPHeaderField:@"Accept"];
	} else if (OTRestMappingFormatJSON == _format) {
		[_client setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	}
}

#pragma mark Model Methods

- (void)registerModel:(Class<OTRestModelMappable>)class forElementNamed:(NSString*)elementName {
	[_mapper registerModel:class forElementNamed:elementName];
}

/**
 * Load a model from a restful resource and invoke the callback
 */
- (OTRestRequest*)loadModel:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	OTRestModelLoader* loader = [[OTRestModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	return [_client get:resourcePath delegate:loader callback:loader.memberCallback];
}

/**
 * Load a collection of models from a restful resource and invoke the callback
 */
- (OTRestRequest*)loadModels:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	OTRestModelLoader* loader = [[OTRestModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	return [_client get:resourcePath delegate:loader callback:loader.collectionCallback];
}

- (OTRestRequest*)getModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback {
	OTRestModelLoader* loader = [[OTRestModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	return [_client get:[model memberPath] delegate:loader callback:loader.memberCallback];
}

- (OTRestRequest*)postModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback {
	OTRestModelLoader* loader = [[OTRestModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	OTRestParams* params = [OTRestParams paramsWithDictionary:[model resourceParams]];
	return [_client post:[model collectionPath] params:params delegate:loader callback:loader.memberCallback];
}

- (OTRestRequest*)putModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback {
	OTRestModelLoader* loader = [[OTRestModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	OTRestParams* params = [OTRestParams paramsWithDictionary:[model resourceParams]];
	return [_client put:[model memberPath] params:params delegate:loader callback:loader.memberCallback];
}

- (OTRestRequest*)deleteModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback {
	// TODO: are we responsible for deleting the object too,
	//		or are we to assume that the caller has/will delete it?
	return [_client delete:[model memberPath] delegate:delegate callback:callback];
}

@end
