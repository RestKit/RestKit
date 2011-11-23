//
//  RKObjectRouter.h
//  RestKit
//
//  Created by Blake Watters on 10/18/10.
//  Copyright 2010 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKRequest.h"

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
 * *NOTE* - The pattern matcher fully supports KVM, so /:key1.otherKey normally resolves as it 
 * would in any other KVM situation, ... otherKey is a sub-key on a the object represented by
 * key1.  This presents a problem in situations where you might want to build a pattern like 
 * /:filename.json, where the dot isn't intended as a sub-key on the dynamic "filename", but 
 * rather it is part of the "json" static string.  In these instances, you need to escape the 
 * dot with two backslashes, like so: /:filename\\.json
 * @see RKPathMatcher
 */
- (void)routeClass:(Class)objectClass toResourcePath:(NSString*)resourcePath;

/**
 * Register a mapping from an object class to a resource path for a specific HTTP method.
 * @see RKPathMatcher
 */
- (void)routeClass:(Class)objectClass toResourcePath:(NSString*)resourcePath forMethod:(RKRequestMethod)method;

/**
 * Register a mapping from an object class to a resource path for a specific HTTP method, 
 * optionally adding url escapes to the path.  This urlEscape flag comes in handy when you want to provide
 * your own fully escaped dynamic resource path via a method/attribute on the object model.
 * For example, if your Person model has a string attribute titled "polymorphicResourcePath" that returns 
 * @"/this/is/the/path", you should configure the route with url escapes 'off', otherwise the router will return
 * @"%2Fthis%2Fis%2Fthe%2Fpath".
 * @see RKPathMatcher
 */
- (void)routeClass:(Class)objectClass toResourcePath:(NSString*)resourcePath forMethod:(RKRequestMethod)method escapeRoutedPath:(BOOL)addEscapes;

/**
 * Returns the resource path to send requests for a given object and HTTP method
 */
- (NSString*)resourcePathForObject:(NSObject*)object method:(RKRequestMethod)method;

@end
