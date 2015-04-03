//
//  RKURLEncodedSerialization.m
//  RestKit
//
//  Created by Blake Watters on 9/4/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import "RKURLEncodedSerialization.h"

#pragma mark - AFNetworking

// Taken from https://github.com/AFNetworking/AFNetworking/blob/49f2f8c9a907977ec1b3afb182404ae0a6bce883/AFNetworking/AFURLRequestSerialization.m

static NSString * const RKAFCharactersToBeEscapedInQueryString = @":/?&=;+!@#$()',*";

static NSString * RKAFPercentEscapedQueryStringKeyFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const RKAFCharactersToLeaveUnescapedInQueryStringPairKey = @"[].";

	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)RKAFCharactersToLeaveUnescapedInQueryStringPairKey, (__bridge CFStringRef)RKAFCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

static NSString * AFPercentEscapedQueryStringValueFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)RKAFCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

#pragma mark -

@interface RKAFQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value NS_DESIGNATED_INITIALIZER;

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;
@end

@implementation RKAFQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.field = field;
    self.value = value;

    return self;
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return RKAFPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding);
    } else {
        return [NSString stringWithFormat:@"%@=%@", RKAFPercentEscapedQueryStringKeyFromStringWithEncoding([self.field description], stringEncoding), AFPercentEscapedQueryStringValueFromStringWithEncoding([self.value description], stringEncoding)];
    }
}

@end

#pragma mark -

extern NSArray * RKAFQueryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSArray * RKAFQueryStringPairsFromKeyAndValue(NSString *key, id value);

static NSString * RKAFQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (RKAFQueryStringPair *pair in RKAFQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValueWithEncoding:stringEncoding]];
    }

    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * RKAFQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return RKAFQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * RKAFQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:RKAFQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:RKAFQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:RKAFQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[RKAFQueryStringPair alloc] initWithField:key value:value]];
    }

    return mutableQueryStringComponents;
}

#pragma mark - RestKit

@implementation RKURLEncodedSerialization

+ (id)objectFromData:(NSData *)data error:(NSError **)error
{
    NSString *string = [NSString stringWithUTF8String:[data bytes]];
    return RKDictionaryFromURLEncodedStringWithEncoding(string, NSUTF8StringEncoding);
}

+ (NSData *)dataFromObject:(id)object error:(NSError **)error
{
    NSString *string = RKURLEncodedStringFromDictionaryWithEncoding(object, NSUTF8StringEncoding);
    return [string dataUsingEncoding:NSUTF8StringEncoding];
}

@end

NSDictionary *RKDictionaryFromURLEncodedStringWithEncoding(NSString *URLEncodedString, NSStringEncoding encoding)
{
    NSMutableDictionary *queryComponents = [NSMutableDictionary dictionary];
    for (NSString *keyValuePairString in [URLEncodedString componentsSeparatedByString:@"&"]) {
        NSArray *keyValuePairArray = [keyValuePairString componentsSeparatedByString:@"="];
        if ([keyValuePairArray count] < 2) continue; // Verify that there is at least one key, and at least one value.  Ignore extra = signs
        NSString *key = [keyValuePairArray[0] stringByReplacingPercentEscapesUsingEncoding:encoding];
        NSString *value = [keyValuePairArray[1] stringByReplacingPercentEscapesUsingEncoding:encoding];

        // URL spec says that multiple values are allowed per key
        id results = queryComponents[key];
        if (results) {
            if ([results isKindOfClass:[NSMutableArray class]]) {
                [(NSMutableArray *)results addObject:value];
            } else {
                // On second occurrence of the key, convert into an array
                NSMutableArray *values = [NSMutableArray arrayWithObjects:results, value, nil];
                queryComponents[key] = values;
            }
        } else {
            queryComponents[key] = value;
        }
    }
    return queryComponents;
}

NSString *RKURLEncodedStringFromDictionaryWithEncoding(NSDictionary *dictionary, NSStringEncoding encoding)
{
    return RKAFQueryStringFromParametersWithEncoding(dictionary, encoding);
}

// This replicates `AFPercentEscapedQueryStringPairMemberFromStringWithEncoding`. Should send PR exposing non-static version
NSString *RKPercentEscapedQueryStringFromStringWithEncoding(NSString *string, NSStringEncoding encoding)
{
    // Escape characters that are legal in URIs, but have unintentional semantic significance when used in a query string parameter
    static NSString * const kAFLegalCharactersToBeEscaped = @":/.?&=;+!@$()~";

	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kAFLegalCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
}

NSDictionary *RKQueryParametersFromStringWithEncoding(NSString *string, NSStringEncoding encoding)
{
    NSRange chopRange = [string rangeOfString:@"?"];
    if (chopRange.length > 0) {
        chopRange.location += 1; // we want inclusive chopping up *through *"?"
        if (chopRange.location < [string length]) string = [string substringFromIndex:chopRange.location];
    }
    return RKDictionaryFromURLEncodedStringWithEncoding(string, encoding);
}

