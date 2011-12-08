//
//  RKObjectRouter.m
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

#import "RKObjectRouter.h"
#import "RKClient.h"
#import "NSDictionary+RKRequestSerialization.h"

@implementation RKObjectRouter

- (id)init {
    if ((self = [super init])) {
        _routes = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)dealloc {
    [_routes release];
    [super dealloc];
}

- (void)routeClass:(Class)theClass toResourcePath:(NSString*)resourcePath forMethodName:(NSString*)methodName escapeRoutedPath:(BOOL)addEscapes {
    NSString* className = NSStringFromClass(theClass);
    if (nil == [_routes objectForKey:theClass]) {
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
        [_routes setObject:dictionary forKey:theClass];
    }

    NSMutableDictionary* classRoutes = [_routes objectForKey:theClass];
    if ([classRoutes objectForKey:methodName]) {
    [NSException raise:nil format:@"A route has already been registered for class '%@' and HTTP method '%@'", className, methodName];
    }

    NSMutableDictionary *routeEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       resourcePath, @"resourcePath", [NSNumber numberWithBool:addEscapes], @"addEscapes", nil];
    [classRoutes setValue:routeEntry forKey:methodName];
}

- (NSString*)HTTPVerbForMethod:(RKRequestMethod)method {
    switch (method) {
        case RKRequestMethodGET:
            return @"GET";
            break;
        case RKRequestMethodPOST:
            return @"POST";
            break;
        case RKRequestMethodPUT:
            return @"PUT";
            break;
        case RKRequestMethodDELETE:
            return @"DELETE";
            break;
        default:
            return nil;
            break;
    }
}

// Public

- (void)routeClass:(Class)theClass toResourcePath:(NSString*)resourcePath {
    [self routeClass:theClass toResourcePath:resourcePath forMethodName:@"ANY" escapeRoutedPath:YES];
}

- (void)routeClass:(Class)theClass toResourcePath:(NSString*)resourcePath forMethod:(RKRequestMethod)method {
    [self routeClass:theClass toResourcePath:resourcePath forMethod:method escapeRoutedPath:YES];
}

- (void)routeClass:(Class)theClass toResourcePath:(NSString*)resourcePath forMethod:(RKRequestMethod)method escapeRoutedPath:(BOOL)addEscapes {
    NSString* methodName = [self HTTPVerbForMethod:method];
    [self routeClass:theClass toResourcePath:resourcePath forMethodName:methodName escapeRoutedPath:addEscapes];
}

#pragma mark RKRouter

- (NSString*)resourcePathForObject:(NSObject*)object method:(RKRequestMethod)method {
    NSString* methodName = [self HTTPVerbForMethod:method];
    NSString* className  = NSStringFromClass([object class]);
    NSDictionary* classRoutes = nil;

    // Check for exact matches
    for (Class possibleClass in _routes) {
        if ([object isMemberOfClass:possibleClass]) {
            classRoutes = [_routes objectForKey:possibleClass];
            break;
        }
    }

    // Check for superclass matches
    if (! classRoutes) {
        for (Class possibleClass in _routes) {
            if ([object isKindOfClass:possibleClass]) {
                classRoutes = [_routes objectForKey:possibleClass];
                break;
            }
        }
    }

    NSDictionary *routeEntry = [classRoutes objectForKey:methodName];
    if (!routeEntry)
        routeEntry = [classRoutes objectForKey:@"ANY"];

    if (routeEntry) {
        BOOL addEscapes = [[routeEntry objectForKey:@"addEscapes"] boolValue];
        NSString *path = RKMakePathWithObjectAddingEscapes([routeEntry objectForKey:@"resourcePath"], object, addEscapes);
        return path;
    }

    [NSException raise:@"Unable to find a routable path for object" format:@"Unable to find a routable path for object of type '%@' for HTTP Method '%@'", className, methodName];
    
    return nil;
}

@end
