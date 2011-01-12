//
//  RKDynamicRouter.h
//  RestKit
//
//  Created by Blake Watters on 10/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRouter.h"
#import "RKObjectMappable.h"

/**
 * An implementation of the RKRouter protocol that is suitable for use in either
 * static or dynamic route generation. Static routes are added by simply encoding
 * the resourcePath that the mappable object should be sent to when a GET, POST, PUT
 * or DELETE action is invoked. Dynamic routes are available by encoding key paths into
 * the resourcePath surrounded by parentheses (i.e. /users/(userID))
 */
@interface RKDynamicRouter : NSObject <RKRouter> {
	NSMutableDictionary* _routes;
}

/**
 * Register a mapping from an object class to a resource path. This resourcePath can be static
 * (i.e. /this/is/the/path) or dynamic (i.e. /users/(userID)/(username)). Dynamic routes are
 * evaluated against the object being routed using Key-Value coding and coerced into a string.
 */
- (void)routeClass:(Class<RKObjectMappable>)class toResourcePath:(NSString*)resourcePath;

/**
 * Register a mapping from an object class to a resource path for a specific HTTP method.
 */
- (void)routeClass:(Class<RKObjectMappable>)class toResourcePath:(NSString*)resourcePath forMethod:(RKRequestMethod)method;

@end
