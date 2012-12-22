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

@interface RKResponseDescriptor ()
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, copy, readwrite) NSString *pathPattern;
@property (nonatomic, copy, readwrite) NSString *keyPath;
@property (nonatomic, copy, readwrite) NSIndexSet *statusCodes;
@end

@implementation RKResponseDescriptor

+ (instancetype)responseDescriptorWithMapping:(RKMapping *)mapping
                                  pathPattern:(NSString *)pathPattern
                                      keyPath:(NSString *)keyPath
                                  statusCodes:(NSIndexSet *)statusCodes
{
    NSParameterAssert(mapping);
    RKResponseDescriptor *mappingDescriptor = [self new];
    mappingDescriptor.mapping = mapping;
    mappingDescriptor.pathPattern = pathPattern;
    mappingDescriptor.keyPath = keyPath;
    mappingDescriptor.statusCodes = statusCodes;

    return mappingDescriptor;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p pathPattern=%@ keyPath=%@ statusCodes=%@ : %@>",
            NSStringFromClass([self class]), self, self.pathPattern, self.keyPath, self.statusCodes ? RKStringFromIndexSet(self.statusCodes) : self.statusCodes, self.mapping];
}

- (BOOL)matchesPath:(NSString *)path
{
    if (!self.pathPattern || !path) return YES;
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:self.pathPattern];
    return [pathMatcher matchesPath:path tokenizeQueryStrings:NO parsedArguments:nil];
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

@end
