//
//  RKPathMatcherTest.m
//  RestKit
//
//  Created by Greg Combs on 9/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKTestEnvironment.h"
#import "RKPathMatcher.h"

@interface RKPathMatcherTest : RKTestCase

@end

@implementation RKPathMatcherTest

- (void)testShouldMatchPathsWithQueryArguments
{
    NSDictionary *arguments = nil;
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:@"/this/is/my/backend?foo=bar&this=that"];
    BOOL isMatchingPattern = [pathMatcher matchesPattern:@"/this/is/:controllerName/:entityName" tokenizeQueryStrings:YES parsedArguments:&arguments];
    expect(isMatchingPattern).to.equal(YES);
    expect(arguments).notTo.beEmpty();
    NSDictionary *expectedArguments = @{ @"controllerName": @"my", @"entityName": @"backend", @"foo": @"bar", @"this": @"that" };
    expect(arguments).to.equal(expectedArguments);
}

- (void)testShouldMatchPathsWithEscapedArguments
{
    NSDictionary *arguments = nil;
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:@"/bills/tx/82/SB%2014?apikey=GC12d0c6af"];
    BOOL isMatchingPattern = [pathMatcher matchesPattern:@"/bills/:stateID/:session/:billID" tokenizeQueryStrings:YES parsedArguments:&arguments];
    expect(isMatchingPattern).to.equal(YES);
    expect(arguments).notTo.beEmpty();
    NSDictionary *expectedArguments = @{ @"stateID": @"tx", @"session": @"82", @"billID": @"SB 14", @"apikey": @"GC12d0c6af" };
    expect(arguments).to.equal(expectedArguments);

}

- (void)testShouldMatchPathsWithoutQueryArguments
{
    NSDictionary *arguments = nil;
    RKPathMatcher *patternMatcher = [RKPathMatcher pathMatcherWithPattern:@"github.com/:username"];
    BOOL isMatchingPattern = [patternMatcher matchesPath:@"github.com/jverkoey" tokenizeQueryStrings:NO parsedArguments:&arguments];
    expect(isMatchingPattern).to.equal(YES);
    expect(arguments).notTo.beEmpty();
    NSDictionary *params = @{ @"username": @"jverkoey" };
    expect(arguments).to.equal(params);
}

- (void)testShouldMatchPathsWithoutAnyArguments
{
    NSDictionary *arguments = nil;
    RKPathMatcher *patternMatcher = [RKPathMatcher pathMatcherWithPattern:@"/metadata"];
    BOOL isMatchingPattern = [patternMatcher matchesPath:@"/metadata" tokenizeQueryStrings:NO parsedArguments:&arguments];
    expect(isMatchingPattern).to.equal(YES);
    expect(arguments).to.beEmpty();
}

- (void)testShouldPerformTwoMatchesInARow
{
    NSDictionary *arguments = nil;
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:@"/metadata?apikey=GC12d0c6af"];
    BOOL isMatchingPattern1 = [pathMatcher matchesPattern:@"/metadata/:stateID" tokenizeQueryStrings:YES parsedArguments:&arguments];
    expect(isMatchingPattern1).to.equal(NO);
    BOOL isMatchingPattern2 = [pathMatcher matchesPattern:@"/metadata" tokenizeQueryStrings:YES parsedArguments:&arguments];
    expect(isMatchingPattern2).to.equal(YES);
    expect(arguments).notTo.beNil();
    expect(arguments).to.equal(@{ @"apikey": @"GC12d0c6af" });
}

- (void)testShouldCreatePathsFromInterpolatedObjects
{
    NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"CuddleGuts", @"name", [NSNumber numberWithInt:6], @"age", nil];
    RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:@"/people/:name/:age"];
    NSString *interpolatedPath = [matcher pathFromObject:person addingEscapes:YES interpolatedParameters:nil];
    expect(interpolatedPath).notTo.beNil();
    NSString *expectedPath = @"/people/CuddleGuts/6";
    expect(interpolatedPath).to.equal(expectedPath);
}

- (void)testShouldCreatePathsFromInterpolatedObjectsWithAddedEscapes
{
    NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"JUICE|BOX&121", @"password", @"Joe Bob Briggs", @"name", [NSNumber numberWithInt:15], @"group", nil];
    RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:@"/people/:group/:name?password=:password"];
    NSString *interpolatedPath = [matcher pathFromObject:person addingEscapes:YES interpolatedParameters:nil];
    expect(interpolatedPath).notTo.beNil();
    NSString *expectedPath = @"/people/15/Joe%20Bob%20Briggs?password=JUICE%7CBOX%26121";
    expect(interpolatedPath).to.equal(expectedPath);
}

- (void)testShouldCreatePathsFromInterpolatedObjectsWithoutAddedEscapes
{
    NSDictionary *person = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"JUICE|BOX&121", @"password", @"Joe Bob Briggs", @"name", [NSNumber numberWithInt:15], @"group", nil];
    RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:@"/people/:group/:name?password=:password"];
    NSString *interpolatedPath = [matcher pathFromObject:person addingEscapes:NO interpolatedParameters:nil];
    expect(interpolatedPath).notTo.beNil();
    NSString *expectedPath = @"/people/15/Joe Bob Briggs?password=JUICE|BOX&121";
    expect(interpolatedPath).to.equal(expectedPath);
}

- (void)testShouldCreatePathsThatIncludePatternArgumentsFollowedByEscapedNonPatternDots
{
    NSDictionary *arguments = [NSDictionary dictionaryWithObjectsAndKeys:@"Resources", @"filename", nil];
    RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:@"/directory/:filename\\.json"];
    NSString *interpolatedPath = [matcher pathFromObject:arguments addingEscapes:YES interpolatedParameters:nil];
    expect(interpolatedPath).notTo.beNil();
    NSString *expectedPath = @"/directory/Resources.json";
    expect(interpolatedPath).to.equal(expectedPath);
}

- (void)testThatEscapedParametersAreUnescapedWhenCreatingPathFromObject
{
    NSDictionary *arguments = @{ @"name": @"Blake Watters" };
    RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:@"/names/:name"];
    NSDictionary *params = nil;
    [matcher pathFromObject:arguments addingEscapes:YES interpolatedParameters:&params];
    expect(params).notTo.beNil();
    expect([params objectForKey:@"name"]).to.equal(@"Blake Watters");
}

- (void)testMatchingPathWithTrailingSlashAndQuery
{
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:@"/api/v1/organizations/"];
    BOOL matches = [pathMatcher matchesPath:@"/api/v1/organizations/?client_search=t" tokenizeQueryStrings:NO parsedArguments:nil];
    expect(matches).to.equal(YES);
}

- (void)testThatPatternsAreNotMatchedTooAggressively
{
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:@"/api/v1/organizations"];
    BOOL matches = [pathMatcher matchesPath:@"/api/v1/organizations/1234/another?client_search=t" tokenizeQueryStrings:NO parsedArguments:nil];
    expect(matches).to.equal(NO);
    
    pathMatcher = [RKPathMatcher pathMatcherWithPattern:@"/api/:version/organizations"];
    matches = [pathMatcher matchesPath:@"/api/v1/organizations/1234/another?client_search=t" tokenizeQueryStrings:NO parsedArguments:nil];
    expect(matches).to.equal(NO);
    
    matches = [pathMatcher matchesPath:@"/api/v1/organizations/" tokenizeQueryStrings:NO parsedArguments:nil];
    expect(matches).to.equal(NO);
    
    pathMatcher = [RKPathMatcher pathMatcherWithPattern:@"/api/:version/organizations/:organizationID"];
    matches = [pathMatcher matchesPath:@"/api/v1/organizations/1234" tokenizeQueryStrings:NO parsedArguments:nil];
    expect(matches).to.equal(YES);
}

- (void)testMatchingPathPatternWithTrailingSlash
{
    NSDictionary *argsDictionary = nil;
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:@"/api/v1/organizations/:identifier/"];
    BOOL match = [pathMatcher matchesPath:@"/api/v1/organizations/1/" tokenizeQueryStrings:YES parsedArguments:&argsDictionary];
    expect(match).to.beTruthy();
}

- (void)testMatchingPathPatternWithTrailingSlashAndQueryParameters
{
    NSDictionary *argsDictionary = nil;
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:@"/api/v1/organizations/"];
    BOOL match = [pathMatcher matchesPath:@"/api/v1/organizations/?client_search=s" tokenizeQueryStrings:YES parsedArguments:&argsDictionary];
    expect(match).to.beTruthy();
}

- (void)testThatMatchingPathPatternsDoesNotMatchPathsShorterThanTheInput
{
    NSString *path = @"/categories/some-category-name/articles/the-article-name";
    
    RKPathMatcher *pathMatcher1 = [RKPathMatcher pathMatcherWithPattern:@"/categories"];
    BOOL matches = [pathMatcher1 matchesPath:path tokenizeQueryStrings:NO parsedArguments:nil];
    expect(matches).to.equal(NO);
    
    RKPathMatcher *pathMatcher2 = [RKPathMatcher pathMatcherWithPattern:@"/categories/:categoryName"];
    matches = [pathMatcher2 matchesPath:path tokenizeQueryStrings:NO parsedArguments:nil];
    expect(matches).to.equal(NO);
    
    RKPathMatcher *pathMatcher3 = [RKPathMatcher pathMatcherWithPattern:@"/categories/:categorySlug/articles/:articleSlug"];
    matches = [pathMatcher3 matchesPath:path tokenizeQueryStrings:NO parsedArguments:nil];
    expect(matches).to.equal(YES);
}

@end
