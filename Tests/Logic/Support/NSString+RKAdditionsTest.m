//
//  NSString+RKAdditionsTest.m
//  RestKit
//
//  Created by Josh Brown on 7/13/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "NSString+RKAdditions.h"

@interface NSString_RKAdditionsTest : RKTestCase
@end

@implementation NSString_RKAdditionsTest

- (void)testReturnsNilWhenReceiverHasNoQueryParameters
{
    NSString *string = @"/path";
    assertThat([string queryParametersString], is(equalTo(nil)));
}

- (void)testReturnsQueryParametersStringWhenReceiverHasSingleKeyValuePair
{
    NSString *string = @"/path?foo=bar";
    assertThat([string queryParametersString], is(equalTo(@"foo=bar")));
}

- (void)testReturnsQueryParametersStringWhenReceiverHasTwoKeyValuePairs
{
    NSString *string = @"/path?foo=bar&this=that";
    assertThat([string queryParametersString], is(equalTo(@"foo=bar&this=that")));    
}

@end
