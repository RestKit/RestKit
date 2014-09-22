//
//  RKResponseDescriptor.m
//  RestKit
//
//  Created by Blake Watters on 8/16/12.
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
#import "RKResponseDescriptor.h"
#import "RKHTTPUtilities.h"
#import "RKMapping.h"

// Cloned from AFStringFromIndexSet -- method should be non-static for reuse
NSString *RKStringFromIndexSet(NSIndexSet *indexSet);
NSString *RKStringFromIndexSet(NSIndexSet *indexSet)
{
    NSCParameterAssert(indexSet);
    NSMutableString *string = [NSMutableString string];

    NSRange range = NSMakeRange([indexSet firstIndex], 1);
    while (range.location != NSNotFound) {
        NSUInteger nextIndex = [indexSet indexGreaterThanIndex:range.location];
        while (nextIndex == range.location + range.length) {
            range.length++;
            nextIndex = [indexSet indexGreaterThanIndex:nextIndex];
        }

        if (string.length) {
            [string appendString:@","];
        }

        if (range.length == 1) {
            [string appendFormat:@"%lu", (unsigned long) range.location];
        } else {
            NSUInteger firstIndex = range.location;
            NSUInteger lastIndex = firstIndex + range.length - 1;
            [string appendFormat:@"%lu-%lu", (unsigned long) firstIndex, (unsigned long) lastIndex];
        }

        range.location = nextIndex;
        range.length = 1;
    }

    return string;
}

extern NSString *RKStringDescribingRequestMethod(RKRequestMethod method);

@interface RKResponseDescriptor ()
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, assign, readwrite) RKRequestMethod method;
@property (nonatomic, copy, readwrite) NSString *pathPattern;
@property (nonatomic, strong, readwrite) RKPathMatcher *pathPatternMatcher;
@property (nonatomic, copy, readwrite) NSString *keyPath;
@property (nonatomic, copy, readwrite) NSIndexSet *statusCodes;
@end

@implementation RKResponseDescriptor

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
+ (instancetype)responseDescriptorWithMapping:(RKMapping *)mapping
                                  pathPattern:(NSString *)pathPattern
                                      keyPath:(NSString *)keyPath
                                  statusCodes:(NSIndexSet *)statusCodes
{
    return [self responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:pathPattern keyPath:keyPath statusCodes:statusCodes];
}
#pragma clang diagnostic pop

+ (instancetype)responseDescriptorWithMapping:(RKMapping *)mapping
                                       method:(RKRequestMethod)method
                                  pathPattern:(NSString *)pathPattern
                                      keyPath:(NSString *)keyPath
                                  statusCodes:(NSIndexSet *)statusCodes
{
    NSParameterAssert(mapping);
    RKResponseDescriptor *mappingDescriptor = [self new];
    mappingDescriptor.mapping = mapping;
    mappingDescriptor.method = method;
    mappingDescriptor.pathPattern = pathPattern;
    mappingDescriptor.keyPath = keyPath;
    mappingDescriptor.statusCodes = statusCodes;

    return mappingDescriptor;
}

- (void)setPathPattern:(NSString *)pathPattern
{
    _pathPattern = pathPattern;
    if (pathPattern) {
        self.pathPatternMatcher = [RKPathMatcher pathMatcherWithPattern:pathPattern];
    } else {
        self.pathPatternMatcher = nil;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p method=%@ pathPattern=%@ keyPath=%@ statusCodes=%@ : %@>",
            NSStringFromClass([self class]), self, RKStringDescribingRequestMethod(self.method), self.pathPattern, self.keyPath, self.statusCodes ? RKStringFromIndexSet(self.statusCodes) : self.statusCodes, self.mapping];
}

- (BOOL)matchesPath:(NSString *)path
{
    if (!self.pathPattern || !path) return YES;
    return [self.pathPatternMatcher matchesPath:path tokenizeQueryStrings:NO parsedArguments:nil];
}

- (BOOL)matchesURL:(NSURL *)URL
{
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(URL, self.baseURL);
    if (self.baseURL) {
        if (! RKURLIsRelativeToURL(URL, self.baseURL)) return NO;
        return [self matchesPath:pathAndQueryString];
    } else {
        return [self matchesPath:pathAndQueryString];
    }
}

- (BOOL)matchesResponse:(NSHTTPURLResponse *)response
{
    if (! [self matchesURL:response.URL]) return NO;

    if (self.statusCodes) {
        if (! [self.statusCodes containsIndex:response.statusCode]) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)matchesMethod:(RKRequestMethod)method
{
    return self.method & method;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    if ([self class] != [object class]) {
        return NO;
    }
    return [self isEqualToResponseDescriptor:object];
}

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

- (NSUInteger)hash
{
    return NSUINTROTATE(NSUINTROTATE(NSUINTROTATE([self.mapping hash], NSUINT_BIT / 4) ^ [self.pathPattern hash], NSUINT_BIT / 4) ^ [self.keyPath hash], NSUINT_BIT / 4) ^ [self.statusCodes hash];
}

- (BOOL)isEqualToResponseDescriptor:(RKResponseDescriptor *)otherDescriptor
{
    if (![otherDescriptor isKindOfClass:[RKResponseDescriptor class]]) {
        return NO;
    }

    return
    [self.mapping isEqualToMapping:otherDescriptor.mapping] &&
    self.method == otherDescriptor.method &&
    ((self.pathPattern == otherDescriptor.pathPattern) || [self.pathPattern isEqualToString:otherDescriptor.pathPattern]) &&
    ((self.keyPath == otherDescriptor.keyPath) || [self.keyPath isEqualToString:otherDescriptor.keyPath]) &&
    [self.statusCodes isEqualToIndexSet:otherDescriptor.statusCodes];
}

@end
