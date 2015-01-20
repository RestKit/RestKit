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
#import "RKLog.h"
#import "RKDictionaryUtilities.h"

static NSString *RKEncodeURLString(NSString *unencodedString);
extern NSDictionary *RKQueryParametersFromStringWithEncoding(NSString *string, NSStringEncoding stringEncoding);

// NSString's stringByAddingPercentEscapes doesn't do a complete job (it ignores "/?&", among others)
static NSString *RKEncodeURLString(NSString *unencodedString)
{
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                  NULL,
                                                                                  (__bridge CFStringRef)unencodedString,
                                                                                  NULL,
                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                  kCFStringEncodingUTF8));
    return encodedString;
}

static NSUInteger RKNumberOfSlashesInString(NSString *string)
{
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"/" options:NSRegularExpressionCaseInsensitive error:nil];
    });
    return [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, [string length])];
}

NSString *RKPathFromPatternWithObject(NSString *pathPattern, id object)
{
    NSCAssert(object != NULL, @"Object provided is invalid; cannot create a path from a NULL object");
    RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:pathPattern];
    return [matcher pathFromObject:object addingEscapes:NO interpolatedParameters:nil];
}

@interface RKPathMatcher ()
@property (nonatomic, strong) SOCPattern *socPattern;
@property (nonatomic, copy) NSString *patternString; // SOCPattern keeps it private
@end

@implementation RKPathMatcher

- (id)copyWithZone:(NSZone *)zone
{
    RKPathMatcher *copy = [[[self class] allocWithZone:zone] init];
    copy.socPattern = self.socPattern;
    return copy;
}

+ (instancetype)pathMatcherWithPattern:(NSString *)patternString
{
    NSAssert(patternString != NULL, @"Pattern string must not be empty in order to perform pattern matching.");
    RKPathMatcher *matcher = [self new];
    matcher.socPattern = [SOCPattern patternWithString:patternString];
    matcher.patternString = patternString;
    return matcher;
}

+ (instancetype)pathMatcherWithPath:(NSString *)pathString
{
    RKPathMatcher *matcher = [self new];
    return matcher;
}

- (BOOL)matchesPath:(NSString*)pathString
{
    NSAssert((self.socPattern != NULL && pathString != NULL), @"Matcher is insufficiently configured.  Before attempting pattern matching, you must provide a path string and a pattern to match it against.");
    return [self.socPattern stringMatches:pathString];
}

- (BOOL)itMatchesAndHasParsedArguments:(NSDictionary **)arguments andSourcePath:(NSString*)sourcePath tokenizeQueryStrings:(BOOL)shouldTokenize
{
    NSAssert(self.socPattern != NULL, @"Matcher has no established pattern.  Instantiate it using pathMatcherWithPattern: before attempting a pattern match.");
    NSMutableDictionary *argumentsCollection = [NSMutableDictionary dictionary];
    NSString *rootPath = [sourcePath copy];
    NSArray *components = [sourcePath componentsSeparatedByString:@"?"];
    
    // Bifurcate Source Path From Query Parameters
    
    if ([components count] > 1) {
        rootPath = [components objectAtIndex:0];
        NSDictionary *queryParameters = RKQueryParametersFromStringWithEncoding([components objectAtIndex:1], NSUTF8StringEncoding);
        if (shouldTokenize) {
            [argumentsCollection addEntriesFromDictionary:queryParameters];
        }
    }
    
    bool rootPathMatchesPattern = RKNumberOfSlashesInString(self.patternString) == RKNumberOfSlashesInString(rootPath);
    
    if (![self matchesPath:rootPath]) return NO;
    if (!arguments) return YES && rootPathMatchesPattern;
    NSDictionary *extracted = [self.socPattern parameterDictionaryFromSourceString:rootPath];
    if (extracted) [argumentsCollection addEntriesFromDictionary:RKDictionaryByReplacingPercentEscapesInEntriesFromDictionary(extracted)];
    *arguments = argumentsCollection;
    return YES && rootPathMatchesPattern;
}
// This method is temporarily disabled, as it was not used, and is not thread safe. Don't mess with the instance variables (self.socPattern) when multiple threads can use this class simultaneously.
/*
 - (BOOL)matchesPattern:(NSString *)patternString tokenizeQueryStrings:(BOOL)shouldTokenize parsedArguments:(NSDictionary **)arguments
 {

 NSAssert(patternString != NULL, @"Pattern string must not be empty in order to perform patterm matching.");
 self.socPattern = [SOCPattern patternWithString:patternString];
 return [self itMatchesAndHasParsedArguments:arguments tokenizeQueryStrings:shouldTokenize];
 }
 */
- (BOOL)matchesPath:(NSString *)sourceString tokenizeQueryStrings:(BOOL)shouldTokenize parsedArguments:(NSDictionary **)arguments
{
    return [self itMatchesAndHasParsedArguments:arguments andSourcePath:sourceString tokenizeQueryStrings:shouldTokenize];
}

- (NSString *)pathFromObject:(id)object addingEscapes:(BOOL)addEscapes interpolatedParameters:(NSDictionary **)interpolatedParameters
{
    NSAssert(self.socPattern != NULL, @"Matcher has no established pattern.  Instantiate it using pathMatcherWithPattern: before calling pathFromObject:");
    NSAssert(object != NULL, @"Object provided is invalid; cannot create a path from a NULL object");
    NSString *(^encoderBlock)(NSString *interpolatedString) = nil;
    if (addEscapes) {
        encoderBlock = ^NSString *(NSString *interpolatedString) {
            return RKEncodeURLString(interpolatedString);
        };
    }
    NSString *path = [self.socPattern stringFromObject:object withBlock:encoderBlock];
    if (interpolatedParameters) {
        NSMutableDictionary *parsedParameters = [[self.socPattern parameterDictionaryFromSourceString:path] mutableCopy];
        if (addEscapes) {
            for (NSString *key in [parsedParameters allKeys]) {
                NSString *unescapedParameter = [[parsedParameters objectForKey:key] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [parsedParameters setValue:unescapedParameter forKey:key];
            }
        }
        *interpolatedParameters = parsedParameters;
    }
    return path;
}

@end
