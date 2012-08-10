//
//  NSString+RestKit.m
//  RestKit
//
//  Created by Blake Watters on 6/15/11.
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

#if TARGET_OS_IPHONE
#import <MobileCoreServices/UTType.h>
#else
#import <CoreServices/CoreServices.h>
#endif
#import <CommonCrypto/CommonDigest.h>

#include <netdb.h>
#include <arpa/inet.h>

#import "NSString+RKAdditions.h"
#import "NSDictionary+RKAdditions.h"
#import "RKFixCategoryBug.h"
#import "RKPathMatcher.h"

RK_FIX_CATEGORY_BUG(NSString_RKAdditions)

@implementation NSString (RKAdditions)

- (NSString *)stringByAppendingQueryParameters:(NSDictionary *)queryParameters
{
    if ([queryParameters count] > 0) {
        return [NSString stringWithFormat:@"%@?%@", self, [queryParameters stringWithURLEncodedEntries]];
    }
    return [NSString stringWithString:self];
}

// Deprecated
- (NSString *)appendQueryParams:(NSDictionary *)queryParams
{
    return [self stringByAppendingQueryParameters:queryParams];
}

- (NSString *)interpolateWithObject:(id)object addingEscapes:(BOOL)addEscapes
{
    NSCAssert(object != NULL, @"Object provided is invalid; cannot create a path from a NULL object");
    RKPathMatcher *matcher = [RKPathMatcher matcherWithPattern:self];
    NSString *interpolatedPath = [matcher pathFromObject:object addingEscapes:addEscapes];
    return interpolatedPath;
}

- (NSString *)interpolateWithObject:(id)object
{
    return [self interpolateWithObject:object addingEscapes:YES];
}

- (NSDictionary *)queryParameters
{
    return [self queryParametersUsingEncoding:NSUTF8StringEncoding];
}

- (NSDictionary *)queryParametersUsingEncoding:(NSStringEncoding)encoding
{
    return [self queryParametersUsingArrays:NO encoding:encoding];
}

// TODO: Eliminate...
- (NSDictionary *)queryParametersUsingArrays:(BOOL)shouldUseArrays encoding:(NSStringEncoding)encoding
{
    NSString *stringToParse = self;
    NSRange chopRange = [stringToParse rangeOfString:@"?"];
    if (chopRange.length > 0) {
        chopRange.location += 1; // we want inclusive chopping up *through *"?"
        if (chopRange.location < [stringToParse length])
            stringToParse = [stringToParse substringFromIndex:chopRange.location];
    }
    NSCharacterSet *delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&;"];
    NSMutableDictionary *pairs = [NSMutableDictionary dictionary];
    NSScanner *scanner = [[[NSScanner alloc] initWithString:stringToParse] autorelease];
    while (![scanner isAtEnd]) {
        NSString *pairString = nil;
        [scanner scanUpToCharactersFromSet:delimiterSet intoString:&pairString];
        [scanner scanCharactersFromSet:delimiterSet intoString:NULL];
        NSArray *kvPair = [pairString componentsSeparatedByString:@"="];

        if (!shouldUseArrays) {
            if (kvPair.count == 2) {
                NSString *key = [[kvPair objectAtIndex:0]
                                 stringByReplacingPercentEscapesUsingEncoding:encoding];
                NSString *value = [[kvPair objectAtIndex:1]
                                   stringByReplacingPercentEscapesUsingEncoding:encoding];
                [pairs setObject:value forKey:key];
            }
        }
        else {
            if (kvPair.count == 1 || kvPair.count == 2) {
                NSString *key = [[kvPair objectAtIndex:0]
                                 stringByReplacingPercentEscapesUsingEncoding:encoding];
                NSMutableArray *values = [pairs objectForKey:key];
                if (nil == values) {
                    values = [NSMutableArray array];
                    [pairs setObject:values forKey:key];
                }
                if (kvPair.count == 1) {
                    [values addObject:[NSNull null]];

                } else if (kvPair.count == 2) {
                    NSString *value = [[kvPair objectAtIndex:1]
                                       stringByReplacingPercentEscapesUsingEncoding:encoding];
                    [values addObject:value];
                }
            }
        }
    }
    return [NSDictionary dictionaryWithDictionary:pairs];
}

// NOTE: See http://en.wikipedia.org/wiki/Percent-encoding#Percent-encoding_reserved_characters
- (NSString *)stringByAddingURLEncoding
{
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

- (NSString *)stringByReplacingURLEncoding
{
    return [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSDictionary *)fileExtensionsToMIMETypesDictionary
{
    return [NSDictionary dictionaryWithObjectsAndKeys:@"application/json", @"json", nil];
}

- (NSString *)MIMETypeForPathExtension
{
    NSString *fileExtension = [self pathExtension];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)fileExtension, NULL);
    if (uti != NULL) {
        CFStringRef mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        CFRelease(uti);
        if (mime != NULL) {
            NSString *type = [NSString stringWithString:(NSString *)mime];
            CFRelease(mime);
            return type;
        }
    }

    // Consult our internal dictionary of mappings if not found
    return [[self fileExtensionsToMIMETypesDictionary] valueForKey:fileExtension];
}

- (BOOL)isIPAddress
{
    struct sockaddr_in sa;
    char *hostNameOrIPAddressCString = (char *)[self UTF8String];
    int result = inet_pton(AF_INET, hostNameOrIPAddressCString, &(sa.sin_addr));
    return (result != 0);
}

- (NSString *)stringByAppendingPathComponent:(NSString *)pathComponent isDirectory:(BOOL)isDirectory
{
    NSString *stringWithPathComponent = [self stringByAppendingPathComponent:pathComponent];
    if (isDirectory) return [stringWithPathComponent stringByAppendingString:@"/"];
    return stringWithPathComponent;
}

- (NSString *)MD5
{
    // Create pointer to the string as UTF8
    const char *ptr = [self UTF8String];

    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];

    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, (CC_LONG)strlen(ptr), md5Buffer);

    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH *2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", md5Buffer[i]];
    }

    return output;
}

@end
