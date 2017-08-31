//
//  RKStringTokenizerTest.m
//  RestKit
//
//  Created by Blake Watters on 7/30/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKStringTokenizer.h"

@interface RKStringTokenizerTest : RKTestCase

@end

@implementation RKStringTokenizerTest

- (void)testTokenizingString
{
    RKStringTokenizer *stringTokenizer = [RKStringTokenizer new];
    NSSet *tokens = [stringTokenizer tokenize:@"This is a test"];
    NSSet *expectedTokens = [NSSet setWithArray:@[ @"this", @"is", @"a", @"test" ]];
    expect(tokens).to.equal(expectedTokens);
}

- (void)testTokenizingStringWithSymbols
{
    RKStringTokenizer *stringTokenizer = [RKStringTokenizer new];
    NSSet *tokens = [stringTokenizer tokenize:@"This is a symbol test! $"];
    NSSet *expectedTokens = [NSSet setWithArray:@[ @"this", @"is", @"a", @"symbol", @"test", @"!", @"$" ]];
    expect(tokens).to.equal(expectedTokens);
}

- (void)testTokenizingStringWithStopWords
{
    RKStringTokenizer *stringTokenizer = [RKStringTokenizer new];
    stringTokenizer.stopWords = [NSSet setWithObjects:@"is", @"a", nil];
    NSSet *tokens = [stringTokenizer tokenize:@"This is a stop word test"];
    NSSet *expectedTokens = [NSSet setWithArray:@[ @"this", @"stop", @"word", @"test" ]];
    expect(tokens).to.equal(expectedTokens);
}

- (void)testTokenizingStringWithStopWordsAndSymbols
{
    RKStringTokenizer *stringTokenizer = [RKStringTokenizer new];
    stringTokenizer.stopWords = [NSSet setWithObjects:@"is", @"a", @"!", @"%",  nil];
    NSSet *tokens = [stringTokenizer tokenize:@"This is a stop word symbol test! # %"];
    NSSet *expectedTokens = [NSSet setWithArray:@[ @"this", @"stop", @"word", @"symbol", @"test", @"#" ]];
    expect(tokens).to.equal(expectedTokens);
}

@end
