//
//  RKSearchTokenizerTest.m
//  RestKit
//
//  Created by Blake Watters on 7/30/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKSearchTokenizer.h"

@interface RKSearchTokenizerTest : RKTestCase

@end

@implementation RKSearchTokenizerTest

- (void)testTokenizingString
{
    RKSearchTokenizer *stringTokenizer = [RKSearchTokenizer new];
    NSSet *tokens = [stringTokenizer tokenize:@"This is a test"];
    assertThat(tokens, is(equalTo([NSSet setWithArray:@[ @"this", @"is", @"a", @"test" ]])));
}

- (void)testTokenizingStringWithStopWords
{
    RKSearchTokenizer *stringTokenizer = [RKSearchTokenizer new];
    stringTokenizer.stopWords = [NSSet setWithObjects:@"is", @"a", nil];
    NSSet *tokens = [stringTokenizer tokenize:@"This is a test"];
    assertThat(tokens, is(equalTo([NSSet setWithArray:@[ @"this", @"test" ]])));
}

@end
