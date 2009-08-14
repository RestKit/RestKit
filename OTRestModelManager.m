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

- (id)initWithBaseURL:(NSString*)baseURL {
	if (self = [super init]) {
		_mapper = [[OTRestModelMapper alloc] init];
		_client = [[OTRestClient clientWithBaseURL:baseURL] retain];
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


#pragma mark Model Methods

- (void)registerModel:(Class)class forElementNamed:(NSString*)elementName {
	[_mapper registerModel:class forElementNamed:elementName];
}

/**
 * Load a model from a restful resource and invoke the callback
 */
- (OTRestRequest*)getModel:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	OTRestModelLoader* loader = [[OTRestModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	return [_client get:resourcePath delegate:loader callback:loader.memberCallback];
}

/**
 * Load a collection of models from a restful resource and invoke the callback
 */
- (OTRestRequest*)getModels:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	OTRestModelLoader* loader = [[OTRestModelLoader alloc] initWithMapper:self.mapper];
	loader.delegate = delegate;
	loader.callback = callback;
	
	return [_client get:resourcePath delegate:loader callback:loader.collectionCallback];
}


@end
