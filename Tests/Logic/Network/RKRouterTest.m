//
//  RKRouterTest.m
//  RestKit
//
//  Created by Blake Watters on 12/7/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKRouter.h"

@interface RKRouterTest : RKTestCase
@end

@implementation RKRouterTest

- (void)testChangingBaseURL
{
    NSURL *originalURL = [NSURL URLWithString:@"http://restkit.org/"];
    NSURL *newURL = [NSURL URLWithString:@"http://google.com/"];
    RKRouter *router = [[RKRouter alloc] initWithBaseURL:originalURL];
    router.baseURL = newURL;
    expect(router.baseURL).to.equal(newURL);
}

@end
