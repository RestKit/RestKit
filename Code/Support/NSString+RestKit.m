//
//  NSString+RestKit.m
//  RestKit
//
//  Created by Blake Watters on 6/15/11.
//  Copyright 2011 Two Toasters
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

- (NSDictionary*)queryParametersUsingEncoding:(NSStringEncoding)encoding {
    return [self queryParametersUsingArrays:NO encoding:encoding];
}

- (NSDictionary*)queryParametersUsingArrays:(BOOL)shouldUseArrays encoding:(NSStringEncoding)encoding {
    NSString *stringToParse = self;
    NSRange chopRange = [stringToParse rangeOfString:@"?"];
    if (chopRange.length > 0) {
        chopRange.location+=1; // we want inclusive chopping up *through* "?"
        if (chopRange.location < [stringToParse length])
            stringToParse = [stringToParse substringFromIndex:chopRange.location];
    }
    NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&;"];
    NSMutableDictionary* pairs = [NSMutableDictionary dictionary];
    NSScanner* scanner = [[[NSScanner alloc] initWithString:stringToParse] autorelease];
    while (![scanner isAtEnd]) {
        NSString* pairString = nil;
        [scanner scanUpToCharactersFromSet:delimiterSet intoString:&pairString];
        [scanner scanCharactersFromSet:delimiterSet intoString:NULL];
        NSArray* kvPair = [pairString componentsSeparatedByString:@"="];
        
        if (!shouldUseArrays) {
            if (kvPair.count == 2) {
                NSString* key = [[kvPair objectAtIndex:0]
                                 stringByReplacingPercentEscapesUsingEncoding:encoding];
                NSString* value = [[kvPair objectAtIndex:1]
                                   stringByReplacingPercentEscapesUsingEncoding:encoding];
                [pairs setObject:value forKey:key];
            }
        }
        else {
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
    }
    return [NSDictionary dictionaryWithDictionary:pairs];
}

@end
