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

- (void)itShouldMatchPathsWithDeprecatedParentheses {
    NSDictionary *arguments = nil;
    RKPathMatcher* patternMatcher = [RKPathMatcher matcherWithPattern:@"github.com/(username)"];
    BOOL isMatchingPattern = [patternMatcher matchesPath:@"github.com/jverkoey" tokenizeQueryStrings:NO parsedArguments:&arguments];
    assertThatBool(isMatchingPattern, is(equalToBool(YES)));
}

- (void)itShouldCreatePathsFromInterpolatedObjects {
    NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"CuddleGuts", @"name", [NSNumber numberWithInt:6], @"age", nil];
    RKPathMatcher *matcher = [RKPathMatcher matcherWithPattern:@"/people/:name/:age"];
    NSString *interpolatedPath = [matcher pathFromObject:person];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/CuddleGuts/6";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
}

- (void)itShouldCreatePathsFromInterpolatedObjectsWithDeprecatedParentheses {
    NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"CuddleGuts", @"name", [NSNumber numberWithInt:6], @"age", nil];
    RKPathMatcher *matcher = [RKPathMatcher matcherWithPattern:@"/people/(name)/(age)"];
    NSString *interpolatedPath = [matcher pathFromObject:person];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/CuddleGuts/6";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
}

- (void)itShouldCreatePathsFromInterpolatedObjectsWithAddedEscapes {
    NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"JUICE|BOX&121", @"password", @"Joe Bob Briggs", @"name", [NSNumber numberWithInt:15], @"group", nil];
    RKPathMatcher *matcher = [RKPathMatcher matcherWithPattern:@"/people/:group/:name?password=:password"];
    NSString *interpolatedPath = [matcher pathFromObject:person];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/15/Joe%20Bob%20Briggs?password=JUICE%7CBOX%26121";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));

}

- (void)itShouldCreatePathsFromInterpolatedObjectsWithoutAddedEscapes {
    NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"JUICE|BOX&121", @"password", @"Joe Bob Briggs", @"name", [NSNumber numberWithInt:15], @"group", nil];
    RKPathMatcher *matcher = [RKPathMatcher matcherWithPattern:@"/people/:group/:name?password=:password"];
    NSString *interpolatedPath = [matcher pathFromObject:person addingEscapes:NO];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/15/Joe Bob Briggs?password=JUICE|BOX&121";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
    
}
@end
