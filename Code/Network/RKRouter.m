//
//  RKRouter.m
//  RestKit
//
//  Created by Blake Watters on 6/20/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import "RKRouter.h"
#import "RKRouteSet.h"
#import "RKRoute.h"
#import "RKRequest.h"
#import "RKURL.h"
#import "RKPathMatcher.h"

@implementation RKRouter

@synthesize baseURL = _baseURL;
@synthesize routeSet = _routeSet;

- (id)initWithBaseURL:(RKURL *)baseURL
{
    self = [self init];
    if (self) {
        self.baseURL = baseURL;
    }
    
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.routeSet = [[RKRouteSet new] autorelease];
    }
    
    return self;
}

- (void)dealloc
{
    self.routeSet = nil;
    [super dealloc];
}

- (RKURL *)URLForRouteNamed:(NSString *)routeName method:(out RKRequestMethod *)method object:(id)object
{
    RKRoute *route = [self.routeSet routeForName:routeName];
    if (! route) return nil;
    if (method) *method = route.method;
    return [self.baseURL URLByAppendingResourcePath:[self resourcePathFromRoute:route forObject:object]];
}

- (RKURL *)URLForObject:(id)object method:(RKRequestMethod)method
{
    RKRoute *route = [self.routeSet routeForObject:object method:method];
    if (! route) return nil;
    return [self.baseURL URLByAppendingResourcePath:[self resourcePathFromRoute:route forObject:object]];
}

- (RKURL *)URLForRelationship:(NSString *)relationshipName ofObject:(id)object method:(RKRequestMethod)method
{
    RKRoute *route = [self.routeSet routeForRelationship:relationshipName ofClass:[object class] method:method];
    if (! route) return nil;
    return [self.baseURL URLByAppendingResourcePath:[self resourcePathFromRoute:route forObject:object]];
}

- (NSString *)resourcePathFromRoute:(RKRoute *)route forObject:(id)object
{
    if (! object) return route.resourcePathPattern;
    RKPathMatcher *pathMatcher = [RKPathMatcher matcherWithPattern:route.resourcePathPattern];
    return [pathMatcher pathFromObject:object addingEscapes:route.shouldEscapeResourcePath];
}

@end

@implementation RKRouter (Deprecations)

- (NSString *)resourcePathForObject:(NSObject *)object method:(RKRequestMethod)method DEPRECATED_ATTRIBUTE
{
    return [[self URLForObject:object method:method] resourcePath];
}

- (void)routeClass:(Class)objectClass toResourcePathPattern:(NSString*)resourcePathPattern DEPRECATED_ATTRIBUTE
{
    [self.routeSet addRoute:[RKRoute routeWithClass:objectClass resourcePathPattern:resourcePathPattern method:RKRequestMethodAny]];
}

- (void)routeClass:(Class)objectClass toResourcePathPattern:(NSString*)resourcePathPattern forMethod:(RKRequestMethod)method DEPRECATED_ATTRIBUTE
{
    [self.routeSet addRoute:[RKRoute routeWithClass:objectClass resourcePathPattern:resourcePathPattern method:method]];
}

- (void)routeClass:(Class)objectClass toResourcePathPattern:(NSString*)resourcePathPattern forMethod:(RKRequestMethod)method escapeRoutedPath:(BOOL)addEscapes DEPRECATED_ATTRIBUTE
{
    RKRoute *route = [RKRoute routeWithClass:objectClass resourcePathPattern:resourcePathPattern method:method];
    route.shouldEscapeResourcePath = addEscapes;
    [self.routeSet addRoute:route];
}

@end
