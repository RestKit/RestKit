//
//  RKStaticRouter.h
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRouter.h"
#import "RKObjectMappable.h"

@interface RKStaticRouter : NSObject <RKRouter> {
	NSMutableDictionary* _routes;
}

/**
 * Register a static mapping from an object class to a resource path
 */
- (void)routeClass:(Class<RKObjectMappable>)class toPath:(NSString*)path;

/**
 * Register a static mapping from an object class to a resource path for a given HTTP method
 */
- (void)routeClass:(Class<RKObjectMappable>)class toPath:(NSString*)path forMethod:(RKRequestMethod)method;

@end
