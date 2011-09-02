//
//  RKPathMatcher.m
//  RestKit
//
//  Created by Greg Combs on 9/2/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import "RKPathMatcher.h"
#import "SOCKit.h"

@interface RKPathMatcher() 
@property (nonatomic,retain) SOCPattern *socPattern;
@property (nonatomic,copy) NSString *sourcePath;
@property (nonatomic,retain) NSMutableDictionary *parsedArguments;
@end


@implementation RKPathMatcher
@synthesize socPattern;
@synthesize sourcePath;
@synthesize parsedArguments;

- (void)dealloc {
    self.socPattern = nil;
    self.sourcePath = nil;
    self.parsedArguments = nil;
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
    return matcher;
}

- (BOOL)matches {
    NSCParameterAssert(self.socPattern != NULL && self.sourcePath != NULL);
    return [self.socPattern stringMatches:self.sourcePath];
}

- (NSMutableDictionary *)extractParameters {
    return [[[self.socPattern extractParameterKeyValuesFromSourceString:self.sourcePath] mutableCopy] autorelease];
}

- (BOOL)matchesPattern:(NSString *)patternString tokenizeQueryStrings:(BOOL)tokenizeQueryStrings parsedArguments:(NSDictionary **)arguments {
    NSCParameterAssert(patternString != NULL);
    self.socPattern = [SOCPattern patternWithString:patternString];
    BOOL isMatching = [self matches];
    if (isMatching && tokenizeQueryStrings == YES && arguments) {
        self.parsedArguments = [self extractParameters];
        *arguments = parsedArguments;
        return YES;
    }
    return isMatching;
}

- (BOOL)matchesPath:(NSString *)sourceString tokenizeQueryStrings:(BOOL)tokenizeQueryStrings parsedArguments:(NSDictionary **)arguments {
    self.sourcePath = sourceString;
    BOOL isMatching = [self matches];
    if (isMatching && tokenizeQueryStrings == YES && arguments) {
        self.parsedArguments = [self extractParameters];
        *arguments = parsedArguments;
        return YES;
    }
    return isMatching;
}

@end
