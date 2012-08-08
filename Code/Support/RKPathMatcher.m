//
//  RKPathMatcher.m
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

#import "RKPathMatcher.h"
#import "SOCKit.h"
#import "NSString+RKAdditions.h"
#import "NSDictionary+RKAdditions.h"
#import "RKLog.h"

BOOL RKPathUsesParentheticalParameters(NSString *path);
NSString *RKPathPatternFindAndReplaceParensWithColons(NSString *pattern);
NSString *RKEncodeURLString(NSString *unencodedString);

BOOL RKPathUsesParentheticalParameters(NSString *path) {
    NSCharacterSet *parens = [NSCharacterSet characterSetWithCharactersInString:@"()"];
    NSArray *parenComponents = [path componentsSeparatedByCharactersInSet:parens];
    return (parenComponents != NULL && [parenComponents count] > 1);
}

NSString *RKPathPatternFindAndReplaceParensWithColons(NSString *pattern) {
    if (RKPathUsesParentheticalParameters(pattern)) {
        RKLogWarning(@"Use of encapsulating parentheses for pattern parameters is deprecated.  Use a single colon instead. For example, instead of /group/(role)/(user) you should use /group/:role/:user");
        NSString *noTrailingParen = [pattern stringByReplacingOccurrencesOfString:@")" withString:@""];
        pattern = [noTrailingParen stringByReplacingOccurrencesOfString:@"(" withString:@":"];
    }
    return pattern;
}

// NSString's stringByAddingPercentEscapes doesn't do a complete job (it ignores "/?&", among others)
NSString *RKEncodeURLString(NSString *unencodedString) {
    NSString *encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                  NULL,
                                                                                  (CFStringRef)unencodedString,
                                                                                  NULL,
                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                  kCFStringEncodingUTF8);
    return [encodedString autorelease];
}

@interface RKPathMatcher ()
@property (nonatomic, retain) SOCPattern *socPattern;
@property (nonatomic, copy) NSString *sourcePath;
@property (nonatomic, copy) NSString *rootPath;
@property (copy, readwrite) NSDictionary *queryParameters;
@end

@implementation RKPathMatcher
@synthesize socPattern = socPattern_;
@synthesize sourcePath = sourcePath_;
@synthesize rootPath = rootPath_;
@synthesize queryParameters = queryParameters_;

- (id)copyWithZone:(NSZone *)zone
{
    RKPathMatcher *copy = [[[self class] allocWithZone:zone] init];
    copy.socPattern = self.socPattern;
    copy.sourcePath = self.sourcePath;
    copy.rootPath = self.rootPath;
    copy.queryParameters = self.queryParameters;

    return copy;
}

- (void)dealloc
{
    self.socPattern = nil;
    self.sourcePath = nil;
    self.rootPath = nil;
    self.queryParameters = nil;
    [super dealloc];
}

+ (RKPathMatcher *)matcherWithPattern:(NSString *)patternString
{
    NSAssert(patternString != NULL, @"Pattern string must not be empty in order to perform pattern matching.");
    patternString = RKPathPatternFindAndReplaceParensWithColons(patternString);
    RKPathMatcher *matcher = [[[RKPathMatcher alloc] init] autorelease];
    matcher.socPattern = [SOCPattern patternWithString:patternString];
    return matcher;
}

+ (RKPathMatcher *)matcherWithPath:(NSString *)pathString
{
    RKPathMatcher *matcher = [[[RKPathMatcher alloc] init] autorelease];
    matcher.sourcePath = pathString;
    matcher.rootPath = pathString;
    return matcher;
}

- (BOOL)matches
{
    NSAssert( (self.socPattern != NULL && self.rootPath != NULL), @"Matcher is insufficiently configured.  Before attempting pattern matching, you must provide a path string and a pattern to match it against.");
    return [self.socPattern stringMatches:self.rootPath];
}

- (BOOL)bifurcateSourcePathFromQueryParameters
{
    NSArray *components = [self.sourcePath componentsSeparatedByString:@"?"];
    if ([components count] > 1) {
        self.rootPath = [components objectAtIndex:0];
        self.queryParameters = [[components objectAtIndex:1] queryParametersUsingEncoding:NSUTF8StringEncoding];
        return YES;
    }
    return NO;
}

- (BOOL)itMatchesAndHasParsedArguments:(NSDictionary **)arguments tokenizeQueryStrings:(BOOL)shouldTokenize
{
    NSAssert(self.socPattern != NULL, @"Matcher has no established pattern.  Instantiate it using matcherWithPattern: before attempting a pattern match.");
    NSMutableDictionary *argumentsCollection = [NSMutableDictionary dictionary];
    if ([self bifurcateSourcePathFromQueryParameters]) {
        if (shouldTokenize) {
            [argumentsCollection addEntriesFromDictionary:self.queryParameters];
        }
    }
    if (![self matches])
        return NO;
    if (!arguments) {
        return YES;
    }
    NSDictionary *extracted = [self.socPattern parameterDictionaryFromSourceString:self.rootPath];
    if (extracted)
        [argumentsCollection addEntriesFromDictionary:[extracted dictionaryByReplacingPercentEscapesInEntries]];
    *arguments = argumentsCollection;
    return YES;
}

- (BOOL)matchesPattern:(NSString *)patternString tokenizeQueryStrings:(BOOL)shouldTokenize parsedArguments:(NSDictionary **)arguments
{
    NSAssert(patternString != NULL, @"Pattern string must not be empty in order to perform patterm matching.");
    patternString = RKPathPatternFindAndReplaceParensWithColons(patternString);
    self.socPattern = [SOCPattern patternWithString:patternString];
    return [self itMatchesAndHasParsedArguments:arguments tokenizeQueryStrings:shouldTokenize];
}

- (BOOL)matchesPath:(NSString *)sourceString tokenizeQueryStrings:(BOOL)shouldTokenize parsedArguments:(NSDictionary **)arguments
{
    self.sourcePath = sourceString;
    self.rootPath = sourceString;
    return [self itMatchesAndHasParsedArguments:arguments tokenizeQueryStrings:shouldTokenize];
}

- (NSString *)pathFromObject:(id)object
{
    return [self pathFromObject:object addingEscapes:YES];
}


- (NSString *)pathFromObject:(id)object addingEscapes:(BOOL)addEscapes
{
    NSAssert(self.socPattern != NULL, @"Matcher has no established pattern.  Instantiate it using matcherWithPattern: before calling pathFromObject:");
    NSAssert(object != NULL, @"Object provided is invalid; cannot create a path from a NULL object");
    NSString *(^encoderBlock)(NSString *interpolatedString) = nil;
    if (addEscapes)
        encoderBlock = ^NSString *(NSString *interpolatedString) {
            return RKEncodeURLString(interpolatedString);
        };
    NSString *path = [self.socPattern stringFromObject:object withBlock:encoderBlock];
    return path;
}

@end
