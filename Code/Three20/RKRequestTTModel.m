//
//  RKRequestTTModel.m
//  RestKit
//
//  Created by Blake Watters on 2/9/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRequestTTModel.h"

@implementation RKRequestTTModel

@synthesize model = _model;

- (id)initWithResourcePath:(NSString*)resourcePath {
	if (self = [self init]) {
		_model = [[RKRequestModel alloc] initWithResourcePath:resourcePath delegate:self];
	}
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params {
	if (self = [self init]) {
		_model = [[RKRequestModel alloc] initWithResourcePath:resourcePath params:params delegate:self];
	}
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass{
	if (self = [self init]) {
		_model = [[RKRequestModel alloc] initWithResourcePath:resourcePath params:params objectClass:klass delegate:self];
	}
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass keyPath:(NSString*)keyPath {
	if (self = [self init]) {
		_model = [[RKRequestModel alloc] initWithResourcePath:resourcePath params:params objectClass:klass keyPath:keyPath delegate:self];
	}
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)init {
	if (self = [super init]) {
		_model = nil;
	}
	return self;
}

- (void)dealloc {
	[_model release];
	_model = nil;
	[super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TTModel

- (BOOL)isLoaded {
	return _model.loaded;
}

- (BOOL)isLoading {
	return nil != _model.objectLoader;
}

- (BOOL)isLoadingMore {
	return NO;
}

- (BOOL)isOutdated {
	return NO;
}

- (void)cancel {
	if (_model && _model.objectLoader.request) {
		[_model.objectLoader.request cancel];
	}
}

- (void)invalidate:(BOOL)erase {
	// TODO: Note sure how to handle erase...
	[_model clearLoadedTime];
}

- (void)reset {
	[_model reset];
}

- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more {
	[_model load];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// RKRequestModelDelegate

- (void)rkModelDidStartLoad {
	[self didStartLoad];
}

- (void)rkModelDidFailLoadWithError:(NSError*)error {
	[self didFailLoadWithError:error];
}

- (void)rkModelDidCancelLoad {
	[self didCancelLoad];
}

- (void)rkModelDidLoad {
	[self didFinishLoad];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (NSArray*)objects {
	return _model.objects;
}

@end
