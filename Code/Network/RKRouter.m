//
//  RKRouter.m
//  RestKit
//
//  Created by Blake Watters on 6/20/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

- (RKURL *)URLForRouteNamed:(NSString *)routeName method:(out RKRequestMethod *)method
{
    RKRoute *route = [self.routeSet routeForName:routeName];
    if (! route) return nil;
    if (method) *method = route.method;
    return [self.baseURL URLByAppendingResourcePath:[self resourcePathFromRoute:route forObject:nil]];
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
