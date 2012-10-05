//
//  RKPathUtilitiesTest.m
//  RestKit
//
//  Created by Blake Watters on 10/5/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKPathUtilities.h"

@interface RKPathUtilitiesTest : RKTestCase

@end

@implementation RKPathUtilitiesTest

- (void)testPathNormalizationRemovesTrailingSlash
{
    NSString *normalizedPath = RKPathNormalize(@"/api/v1/organizations/");
    expect(normalizedPath).to.equal(@"/api/v1/organizations");
}

- (void)testPathNormalizationAddsLeadingSlash
{
    NSString *normalizedPath = RKPathNormalize(@"api/v1/organizations/");
    expect(normalizedPath).to.equal(@"/api/v1/organizations");
}

- (void)testPathNormalizationRemovesDuplicateSlashes
{
    NSString *normalizedPath = RKPathNormalize(@"api//v1/organizations//");
    expect(normalizedPath).to.equal(@"/api/v1/organizations");
}

@end
