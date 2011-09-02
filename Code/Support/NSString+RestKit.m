//
//  NSString+RestKit.m
//  RestKit
//
//  Created by Blake Watters on 6/15/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "NSString+RestKit.h"
#import "../Network/RKClient.h"
#import "RKFixCategoryBug.h"

RK_FIX_CATEGORY_BUG(NSString_RestKit)

@implementation NSString (RestKit)

- (NSString*)appendQueryParams:(NSDictionary*)queryParams {
    return RKPathAppendQueryParams(self, queryParams);
}

- (NSString*)interpolateWithObject:(id)object {
    return RKMakePathWithObject(self, object);
}

/**
 * Returns a dictionary of parameter keys and values given a URL-style query string
 * on the receiving object.
 *
 * This method originally appeared as queryContentsUsingEncoding: in the Three20 project:
 * https://github.com/facebook/three20/blob/master/src/Three20Core/Sources/NSStringAdditions.m
 *
 */
- (NSDictionary*)queryParametersUsingEncoding:(NSStringEncoding)encoding {
    NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&;"];
    NSMutableDictionary* pairs = [NSMutableDictionary dictionary];
    NSScanner* scanner = [[[NSScanner alloc] initWithString:self] autorelease];
    while (![scanner isAtEnd]) {
        NSString* pairString = nil;
        [scanner scanUpToCharactersFromSet:delimiterSet intoString:&pairString];
        [scanner scanCharactersFromSet:delimiterSet intoString:NULL];
        NSArray* kvPair = [pairString componentsSeparatedByString:@"="];
        if (kvPair.count == 1 || kvPair.count == 2) {
            NSString* key = [[kvPair objectAtIndex:0]
                             stringByReplacingPercentEscapesUsingEncoding:encoding];
            NSMutableArray* values = [pairs objectForKey:key];
            if (nil == values) {
                values = [NSMutableArray array];
                [pairs setObject:values forKey:key];
            }
            if (kvPair.count == 1) {
                [values addObject:[NSNull null]];
                
            } else if (kvPair.count == 2) {
                NSString* value = [[kvPair objectAtIndex:1]
                                   stringByReplacingPercentEscapesUsingEncoding:encoding];
                [values addObject:value];
            }
        }
    }
    return [NSDictionary dictionaryWithDictionary:pairs];
}


@end
