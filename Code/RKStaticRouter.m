//
//  RKStaticRouter.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKStaticRouter.h"

@implementation RKStaticRouter

- (void)routeClass:(Class<RKResourceMappable>)class toPath:(NSString*)resourcePath {
	// Turn class name into a string
	// Add subdictionary with class name
}

- (void)routeClass:(Class)class toPath:(NSString*)resourcePath forMethod:(RKRequestMethod)method {
}

#pragma mark RKRouter

- (NSString*)pathForObject:(NSObject<RKResourceMappable>*)resource method:(RKRequestMethod)method {
	return nil;
}

- (NSObject<RKRequestSerializable>*)serializationForObject:(NSObject<RKResourceMappable>*)resource method:(RKRequestMethod)method {
	return nil;
}

@end
