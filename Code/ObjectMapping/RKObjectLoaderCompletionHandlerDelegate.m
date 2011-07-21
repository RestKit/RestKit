//
//  RKObjectLoaderCompletionHandlerDelegate.m
//  RestKit
//
//  Created by Jeff Seibert on 7/21/11.
//  Copyright 2011 Crashlytics, Inc. All rights reserved.
//

#import "RKObjectLoaderCompletionHandlerDelegate.h"


@interface RKObjectLoaderCompletionHandlerDelegate (Private)

- (id)initWithLoadHandler:(void (^)(RKObjectLoader *loader, NSArray *objects))loadHandler
		   failureHandler:(void (^)(RKObjectLoader *loader, NSError *error))failureHandler;

@end


@implementation RKObjectLoaderCompletionHandlerDelegate

+ (RKObjectLoaderCompletionHandlerDelegate *)delegateWithLoadHandler:(void (^)(RKObjectLoader *loader, NSArray *objects))loadHandler
													  failureHandler:(void (^)(RKObjectLoader *loader, NSError *error))failureHandler {
	
	// This will -not- be auto-released. We'll clean up after the handlers fire
	return [[RKObjectLoaderCompletionHandlerDelegate alloc] initWithLoadHandler:(void (^)(RKObjectLoader *loader, NSArray *objects))loadHandler
															  failureHandler:(void (^)(RKObjectLoader *loader, NSError *error))failureHandler];
}

- (id)initWithLoadHandler:(void (^)(RKObjectLoader *loader, NSArray *objects))loadHandler
		   failureHandler:(void (^)(RKObjectLoader *loader, NSError *error))failureHandler
{
    if ((self = [super init])) {
        _loadHandler = Block_copy(loadHandler);
		_failureHandler = Block_copy(failureHandler);
    }
    
    return self;
}

- (void)dealloc {
	Block_release(_failureHandler);
	Block_release(_loadHandler);
	
	[super dealloc];
}

#pragma RKObjectLoader Delegate Methods

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
	_loadHandler(objectLoader, objects);
	
	// do not release here. Must wait for -objectLoaderDidFinishLoading:
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
	_failureHandler(objectLoader, error);
	[self release];
}

- (void)objectLoaderDidFinishLoading:(RKObjectLoader *)objectLoader {
	[self release];
}

@end
