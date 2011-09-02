//
//  RKPathMatcher.h
//  RestKit
//
//  Created by Greg Combs on 9/2/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKPathMatcher : NSObject
+(RKPathMatcher *)matcherWithPattern:(NSString *)patternString;
+(RKPathMatcher *)matcherWithPath:(NSString *)pathString;
- (BOOL)matchesPattern:(NSString *)patternString tokenizeQueryStrings:(BOOL)tokenizeQueryStrings parsedArguments:(NSDictionary **)arguments;
- (BOOL)matchesPath:(NSString *)pathString tokenizeQueryStrings:(BOOL)tokenizeQueryStrings parsedArguments:(NSDictionary **)arguments;
@end
