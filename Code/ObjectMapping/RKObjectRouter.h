//
//  RKObjectRouter.h
//  RestKit
//
//  Created by Blake Watters on 10/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "../Network/RKRequest.h"

// TODO: Cleanup the comments in here

/**
 * An implementation of the RKRouter protocol that is suitable for use in either
 * static or dynamic route generation. Static routes are added by simply encoding
 * the resourcePath that the mappable object should be sent to when a GET, POST, PUT
 * or DELETE action is invoked. Dynamic routes are available by encoding key paths into
 * the resourcePath using a single colon delimiter, such as /users/:userID
 */
@interface RKObjectRouter : NSObject {
	NSMutableDictionary* _routes;
}

/**
 * Register a mapping from an object class to a resource path. This resourcePath can be static
 * (i.e. /this/is/the/path) or dynamic (i.e. /users/:userID/:username). Dynamic routes are
 * evaluated against the object being routed using Key-Value coding and coerced into a string.
 */
- (void)routeClass:(Class)objectClass toResourcePath:(NSString*)resourcePath;

/**
 * Register a mapping from an object class to a resource path for a specific HTTP method.
 */
- (void)routeClass:(Class)objectClass toResourcePath:(NSString*)resourcePath forMethod:(RKRequestMethod)method;

/**
 * Register a mapping from an object class to a resource path for a specific HTTP method, 
 * optionally adding url escapes to the path.  This urlEscape flag comes in handy when you want to provide
 * your own fully escaped dynamic resource path via a method/attribute on the object model.
 * For example, if your Person model has a string attribute titled "polymorphicResourcePath" that returns 
 * @"/this/is/the/path", you should configure the route with url escapes 'off', otherwise the router will return
 * @"%2Fthis%2Fis%2Fthe%2Fpath".
 */
- (void)routeClass:(Class)objectClass toResourcePath:(NSString*)resourcePath forMethod:(RKRequestMethod)method escapeRoutedPath:(BOOL)addEscapes;

- (NSString*)resourcePathForObject:(NSObject*)object method:(RKRequestMethod)method;

@end
