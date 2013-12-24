//
//  RKStringTokenizer.m
//  RestKit
//
//  Created by Blake Watters on 7/30/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKStringTokenizer.h"

@implementation RKStringTokenizer

- (NSSet *)tokenize:(NSString *)string
{
    NSMutableSet *tokens = [NSMutableSet set];

    CFLocaleRef locale = CFLocaleCopyCurrent();

    // Remove diacratics and lowercase our input text
    NSString *tokenizeText = string = [string stringByFoldingWithOptions:kCFCompareCaseInsensitive|kCFCompareDiacriticInsensitive locale:[NSLocale systemLocale]];
    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, (__bridge CFStringRef)tokenizeText, CFRangeMake(0, CFStringGetLength((__bridge CFStringRef)tokenizeText)), kCFStringTokenizerUnitWord, locale);
    CFStringTokenizerTokenType tokenType = kCFStringTokenizerTokenNone;

    while (kCFStringTokenizerTokenNone != (tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer))) {
        CFRange tokenRange = CFStringTokenizerGetCurrentTokenRange(tokenizer);

        NSRange range = NSMakeRange(tokenRange.location, tokenRange.length);
        NSString *token = [string substringWithRange:range];

        [tokens addObject:token];
    }

    CFRelease(tokenizer);
    CFRelease(locale);

    // Remove any stop words
    if (self.stopWords) [tokens minusSet:self.stopWords];

    return tokens;
}

@end
