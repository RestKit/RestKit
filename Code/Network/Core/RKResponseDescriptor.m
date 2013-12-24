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

extern NSString *RKStringDescribingHTTPMethods(RKHTTPMethodOptions method);

@interface RKResponseDescriptor ()
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, assign, readwrite) RKHTTPMethodOptions methods;
@property (nonatomic, copy, readwrite) RKPathTemplate *pathTemplate;
@property (nonatomic, copy, readwrite) NSArray *parameterConstraints;
@property (nonatomic, copy, readwrite) NSString *keyPath;
@property (nonatomic, copy, readwrite) NSIndexSet *statusCodes;
@end

@implementation RKResponseDescriptor

+ (instancetype)responseDescriptorWithMethods:(RKHTTPMethodOptions)methods
                           pathTemplateString:(NSString *)pathTemplateString
                         parameterConstraints:(NSArray *)parameterConstraints
                                      keyPath:(NSString *)keyPath
                                  statusCodes:(NSIndexSet *)statusCodes
                                      mapping:(RKMapping *)mapping
{
    return [[self alloc] initWithMethods:methods
                  pathTemplateWithString:pathTemplateString
                    parameterConstraints:parameterConstraints
                                 keyPath:(NSString *)keyPath
                             statusCodes:statusCodes
                                 mapping:mapping];
}

- (id)initWithMethods:(RKHTTPMethodOptions)methods pathTemplateWithString:(NSString *)pathTemplateString parameterConstraints:(NSArray *)parameterConstraints keyPath:(NSString *)keyPath statusCodes:(NSIndexSet *)statusCodes mapping:(RKMapping *)mapping
{
    self = [super init];
    if (self) {
        self.methods = methods;
        self.pathTemplate = nil; // [RKPathTemplate pathTemplateWithString:pathTemplateString];
        self.parameterConstraints = parameterConstraints;
        self.keyPath = keyPath;
        self.statusCodes = statusCodes;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p methods=%@ pathTemplate=%@ keyPath=%@ statusCodes=%@ : %@>",
            NSStringFromClass([self class]), self, RKStringDescribingHTTPMethods(self.methods), self.pathTemplate, self.keyPath, self.statusCodes ? RKStringFromIndexSet(self.statusCodes) : self.statusCodes, self.mapping];
}

- (BOOL)matchesPath:(NSString *)path parameters:(NSDictionary **)parameters
{
//    if (!self.pathPattern || !path) return YES;
//    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:self.pathPattern];
//    return [pathMatcher matchesPath:path tokenizeQueryStrings:NO parsedArguments:nil];
    return YES;
}

- (BOOL)matchesURL:(NSURL *)URL relativeToBaseURL:(NSURL *)baseURL parameters:(NSDictionary **)parameters
{
//    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(URL, self.baseURL);
//    if (self.baseURL) {
//        if (! RKURLIsRelativeToURL(URL, self.baseURL)) return NO;
//        return [self matchesPath:pathAndQueryString];
//    } else {
//        return [self matchesPath:pathAndQueryString];
//    }
    return YES;
}

- (BOOL)matchesResponse:(NSHTTPURLResponse *)response request:(NSURLRequest *)request relativeToBaseURL:(NSURL *)baseURL parameters:(NSDictionary **)parameters
{
//    if (! [self matchesURL:response.URL]) return NO;
//
//    if (self.statusCodes) {
//        if (! [self.statusCodes containsIndex:response.statusCode]) {
//            return NO;
//        }
//    }

    return YES;
}

- (BOOL)matchesMethod:(RKHTTPMethodOptions)method
{
    return self.methods & method;
}

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

- (NSUInteger)hash
{
    return NSUINTROTATE(NSUINTROTATE(NSUINTROTATE([self.mapping hash], NSUINT_BIT / 4) ^ [self.pathTemplate hash], NSUINT_BIT / 4) ^ [self.keyPath hash], NSUINT_BIT / 4) ^ [self.statusCodes hash];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) return YES;
    if (object == nil) return NO;
    if (![object isKindOfClass:[RKResponseDescriptor class]]) return NO;

    RKResponseDescriptor *otherDescriptor = (RKResponseDescriptor *)object;

    return ([self.mapping isEqualToMapping:otherDescriptor.mapping] &&
            self.methods == otherDescriptor.methods &&
            [self.pathTemplate isEqual:otherDescriptor.pathTemplate] &&
            [self.keyPath isEqualToString:otherDescriptor.keyPath] &&
            [self.statusCodes isEqualToIndexSet:otherDescriptor.statusCodes];
}

@end
