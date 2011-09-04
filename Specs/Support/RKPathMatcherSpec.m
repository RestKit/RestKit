//
//  RKPathMatcherSpec.m
//  RestKit
//
//  Created by Greg Combs on 9/2/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKPathMatcher.h"

@interface RKPathMatcherSpec : RKSpec

@end

@implementation RKPathMatcherSpec

- (void)itShouldMatchPathsWithQueryArguments {
    NSDictionary *arguments = nil;
    RKPathMatcher *pathMatcher = [RKPathMatcher matcherWithPath:@"/this/is/my/backend?foo=bar&this=that"];
    BOOL isMatchingPattern = [pathMatcher matchesPattern:@"/this/is/:controllerName/:entityName" tokenizeQueryStrings:YES parsedArguments:&arguments];
    assertThatBool(isMatchingPattern, is(equalToBool(YES)));
    assertThat(arguments, isNot(empty()));
    assertThat(arguments, hasEntries(@"controllerName", @"my", @"entityName", @"backend", @"foo", @"bar", @"this", @"that", nil));
    
}

- (void)itShouldMatchPathsWithEscapedArguments {
    NSDictionary *arguments = nil;
    RKPathMatcher *pathMatcher = [RKPathMatcher matcherWithPath:@"/bills/tx/82/SB%2014?apikey=GC12d0c6af"];
    BOOL isMatchingPattern = [pathMatcher matchesPattern:@"/bills/:stateID/:session/:billID" tokenizeQueryStrings:YES parsedArguments:&arguments];
    assertThatBool(isMatchingPattern, is(equalToBool(YES)));
    assertThat(arguments, isNot(empty()));
    assertThat(arguments, hasEntries(@"stateID", @"tx", @"session", @"82", @"billID", @"SB 14", @"apikey", @"GC12d0c6af", nil));
    
}

- (void)itShouldMatchPathsWithoutQueryArguments {
    NSDictionary *arguments = nil;
    RKPathMatcher* patternMatcher = [RKPathMatcher matcherWithPattern:@"github.com/:username"];
    BOOL isMatchingPattern = [patternMatcher matchesPath:@"github.com/jverkoey" tokenizeQueryStrings:NO parsedArguments:&arguments];
    assertThatBool(isMatchingPattern, is(equalToBool(YES)));
    assertThat(arguments, isNot(empty()));
    assertThat(arguments, hasEntry(@"username", @"jverkoey"));
}

- (void)itShouldMatchPathsWithoutAnyArguments {
    NSDictionary *arguments = nil;
    RKPathMatcher* patternMatcher = [RKPathMatcher matcherWithPattern:@"/metadata"];
    BOOL isMatchingPattern = [patternMatcher matchesPath:@"/metadata" tokenizeQueryStrings:NO parsedArguments:&arguments];
    assertThatBool(isMatchingPattern, is(equalToBool(YES)));
    assertThat(arguments, is(empty()));
}

- (void)itShouldPerformTwoMatchesInARow {
    NSDictionary *arguments = nil;
    RKPathMatcher *pathMatcher = [RKPathMatcher matcherWithPath:@"/metadata?apikey=GC12d0c6af"];
    BOOL isMatchingPattern1 = [pathMatcher matchesPattern:@"/metadata/:stateID" tokenizeQueryStrings:YES parsedArguments:&arguments];
    assertThatBool(isMatchingPattern1, is(equalToBool(NO)));
    BOOL isMatchingPattern2 = [pathMatcher matchesPattern:@"/metadata" tokenizeQueryStrings:YES parsedArguments:&arguments];    
    assertThatBool(isMatchingPattern2, is(equalToBool(YES)));
    assertThat(arguments, isNot(empty()));
    assertThat(arguments, hasEntry(@"apikey", @"GC12d0c6af"));
}

- (void)itShouldNotMatchPathsUsingDeprecatedParentheses {
    NSDictionary *arguments = nil;
    RKPathMatcher* patternMatcher = [RKPathMatcher matcherWithPattern:@"github.com/(username)"];
    BOOL isMatchingPattern = [patternMatcher matchesPath:@"github.com/jverkoey" tokenizeQueryStrings:NO parsedArguments:&arguments];
    assertThatBool(isMatchingPattern, is(equalToBool(NO)));
}


@end
