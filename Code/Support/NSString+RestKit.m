//
//  NSString+RestKit.m
//  RestKit
//
//  Created by Blake Watters on 6/15/11.
//  Copyright 2011 RestKit
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

#if TARGET_OS_IPHONE
#import <MobileCoreServices/UTType.h>
#else
#import <CoreServices/CoreServices.h>
#endif
#import "NSString+RestKit.h"
#import "../Network/RKClient.h"
#import "RKFixCategoryBug.h"

RK_FIX_CATEGORY_BUG(NSString_RestKit)

@implementation NSString (RestKit)

- (NSString *)appendQueryParams:(NSDictionary *)queryParams {
    return RKPathAppendQueryParams(self, queryParams);
}

- (NSString *)interpolateWithObject:(id)object {
    return RKMakePathWithObject(self, object);
}

- (NSDictionary *)queryParameters {
    return [self queryParametersUsingEncoding:NSUTF8StringEncoding];
}

- (NSDictionary*)queryParametersUsingEncoding:(NSStringEncoding)encoding {
    return [self queryParametersUsingArrays:NO encoding:encoding];
}

// TODO: Eliminate...
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

// NOTE: See http://en.wikipedia.org/wiki/Percent-encoding#Percent-encoding_reserved_characters
- (NSString *)stringByAddingURLEncoding {
    CFStringRef legalURLCharactersToBeEscaped = CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`\n\r");
    CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                        (CFStringRef)self,
                                                                        NULL, 
                                                                        legalURLCharactersToBeEscaped,
                                                                        kCFStringEncodingUTF8);
	if (encodedString) {
        return [(NSString *)encodedString autorelease];
    }
    
    // TODO: Log a warning?
    return @"";
}

- (NSString *)stringByReplacingURLEncoding {
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)MIMETypeForPathExtension {
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[self pathExtension], NULL);
    if (uti != NULL) {
        CFStringRef mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        CFRelease(uti);
        if (mime != NULL) {
            NSString *type = [NSString stringWithString:(NSString *)mime];
            CFRelease(mime);
            return type;
        }
    }
	
    return nil;
}

@end
