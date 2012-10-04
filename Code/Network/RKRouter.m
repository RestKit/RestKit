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
#import "RKPathMatcher.h"
#import <objc/runtime.h>

@interface RKRouter ()
@property (nonatomic, strong, readwrite) NSURL *baseURL;
@property (nonatomic, strong, readwrite) RKRouteSet *routeSet;
@end

@implementation RKRouter

- (id)initWithBaseURL:(NSURL *)baseURL
{
    self = [super init];
    if (self) {
        NSParameterAssert(baseURL);
        self.baseURL = baseURL;
        self.routeSet = [[RKRouteSet alloc] init];
    }

    return self;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. Invoke initWithBaseURL: instead.", NSStringFromClass([self class])]
                                 userInfo:nil];
}

- (NSURL *)URLForRouteNamed:(NSString *)routeName method:(out RKRequestMethod *)method object:(id)object
{
    RKRoute *route = [self.routeSet routeForName:routeName];
    if (method) *method = route.method;
    return [self URLWithRoute:route object:object];
}

- (NSURL *)URLForObject:(id)object method:(RKRequestMethod)method
{
    RKRoute *route = [self.routeSet routeForObject:object method:method];
    return [self URLWithRoute:route object:object];
}

- (NSURL *)URLForRelationship:(NSString *)relationshipName ofObject:(id)object method:(RKRequestMethod)method
{
    RKRoute *route = [self.routeSet routeForRelationship:relationshipName ofClass:[object class] method:method];
    return [self URLWithRoute:route object:object];
}

- (NSURL *)URLWithRoute:(RKRoute *)route object:(id)object
{
    NSParameterAssert(route);
    NSURL *URL = [NSURL URLWithString:[self pathFromRoute:route forObject:object] relativeToURL:self.baseURL];
    return URL;
}

- (NSString *)pathFromRoute:(RKRoute *)route forObject:(id)object
{
    if (! object) return route.pathPattern;
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:route.pathPattern];
    return [pathMatcher pathFromObject:object addingEscapes:route.shouldEscapePath];
}

@end
