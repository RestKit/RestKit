//
//  RKDynamicRouter.h
//  RestKit
//
//  Created by Blake Watters on 10/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRouter.h"
#import "RKObjectMappable.h"

@interface RKDynamicRouter : NSObject <RKRouter> {
	NSMutableDictionary* _routes;
}

/**
 * Register a static mapping from an object class to a resource path
 */
- (void)routeClass:(Class<RKObjectMappable>)class toResourcePath:(NSString*)resourcePath;

/**
 * Register a static mapping from an object class to a resource path for a given HTTP method
 */
- (void)routeClass:(Class<RKObjectMappable>)class toResourcePath:(NSString*)resourcePath forMethod:(RKRequestMethod)method;

@end
