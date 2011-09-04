//
//  RKPathMatcher.m
//  RestKit
//
//  Created by Greg Combs on 9/2/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import "RKPathMatcher.h"
#import "SOCKit.h"
#import "NSString+RestKit.h"
#import "NSDictionary+RKAdditions.h"
#import "RKLog.h"

@interface RKPathMatcher()
@property (nonatomic,retain) SOCPattern *socPattern;
@property (nonatomic,copy) NSString *sourcePath;
@property (nonatomic,copy) NSString *rootPath;
@property (retain,readwrite) NSDictionary *queryParameters;
@end

@implementation RKPathMatcher
@synthesize socPattern=socPattern_;
@synthesize sourcePath=sourcePath_;
@synthesize rootPath=rootPath_;
@synthesize queryParameters=queryParameters_;

- (void)dealloc {
    self.socPattern = nil;
    self.sourcePath = nil;
    self.rootPath = nil;
    self.queryParameters = nil;
    [super dealloc];
}

+(RKPathMatcher *)matcherWithPattern:(NSString *)patternString {
    NSCParameterAssert(patternString != NULL);
    RKPathMatcher *matcher = [[[RKPathMatcher alloc] init] autorelease];
    matcher.socPattern = [SOCPattern patternWithString:patternString];
    return matcher;
}

+(RKPathMatcher *)matcherWithPath:(NSString *)pathString {
    RKPathMatcher *matcher = [[[RKPathMatcher alloc] init] autorelease];
    matcher.sourcePath = pathString;
    matcher.rootPath = pathString;
    return matcher;
}

- (BOOL)matches {
    NSCParameterAssert(self.socPattern != NULL && self.rootPath != NULL);
    return [self.socPattern stringMatches:self.rootPath];
}

- (BOOL)bifurcateSourcePathFromQueryParameters {
    NSArray *components = [self.sourcePath componentsSeparatedByString:@"?"];
    if ([components count] > 1) {
        self.rootPath = [components objectAtIndex:0];
        self.queryParameters = [[components objectAtIndex:1] queryParametersUsingEncoding:NSASCIIStringEncoding]; 
        return YES;
    }
    return NO;
}

- (BOOL)itMatchesAndHasParsedArguments:(NSDictionary **)arguments tokenizeQueryStrings:(BOOL)shouldTokenize {
    NSCParameterAssert(self.socPattern != NULL);
    NSMutableDictionary *argumentsCollection = [NSMutableDictionary dictionary];
    if ([self bifurcateSourcePathFromQueryParameters]) {
        if (shouldTokenize) {
            [argumentsCollection addEntriesFromDictionary:self.queryParameters];
        }
    }
    if (![self matches])
        return NO;
    if (!arguments) {
        RKLogWarning(@"The parsed arguments dictionary reference is nil.");
        return YES;
    }
    NSDictionary *extracted = [self.socPattern extractParameterKeyValuesFromSourceString:self.rootPath];
    if (extracted)
        [argumentsCollection addEntriesFromDictionary:[extracted removePercentEscapesFromKeysAndObjects]];
    *arguments = argumentsCollection;
    return YES;
}

- (BOOL)matchesPattern:(NSString *)patternString tokenizeQueryStrings:(BOOL)shouldTokenize parsedArguments:(NSDictionary **)arguments {
    NSCParameterAssert(patternString != NULL);
    self.socPattern = [SOCPattern patternWithString:patternString];
    return [self itMatchesAndHasParsedArguments:arguments tokenizeQueryStrings:shouldTokenize];
}

- (BOOL)matchesPath:(NSString *)sourceString tokenizeQueryStrings:(BOOL)shouldTokenize parsedArguments:(NSDictionary **)arguments {
    self.sourcePath = sourceString;
    self.rootPath = sourceString;
    return [self itMatchesAndHasParsedArguments:arguments tokenizeQueryStrings:shouldTokenize];
}

@end
