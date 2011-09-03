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

- (void)itShouldNotMatchPathsUsingDeprecatedParentheses {
    NSDictionary *arguments = nil;
    RKPathMatcher* patternMatcher = [RKPathMatcher matcherWithPattern:@"github.com/(username)"];
    BOOL isMatchingPattern = [patternMatcher matchesPath:@"github.com/jverkoey" tokenizeQueryStrings:NO parsedArguments:&arguments];
    assertThatBool(isMatchingPattern, is(equalToBool(NO)));
}


@end
