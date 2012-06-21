//
//  RKRouter.h
//  RestKit
//
//  Created by Blake Watters on 6/20/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKRequest.h"
@class RKURL, RKRouteSet;

@interface RKRouter : NSObject

@property (nonatomic, retain) RKURL *baseURL;
@property (nonatomic, retain) RKRouteSet *routeSet;

- (id)initWithBaseURL:(RKURL *)baseURL;

- (RKURL *)URLForRouteNamed:(NSString *)routeName method:(out RKRequestMethod *)method;
- (RKURL *)URLForObject:(id)object method:(RKRequestMethod)method;
- (RKURL *)URLForRelationship:(NSString *)relationshipName ofObject:(id)object method:(RKRequestMethod)method;

@end
