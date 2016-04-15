//
//  RKMappingResult.m
//  RestKit
//
//  Created by Blake Watters on 5/7/11.
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

#import "RKMappingResult.h"

@interface RKMappingResult ()
@property (nonatomic, strong) NSDictionary *keyPathToMappedObjects;
@end

@implementation RKMappingResult

- (instancetype)initWithDictionary:(id)dictionary
{
    NSParameterAssert(dictionary);
    self = [self init];
    if (self) {
        self.keyPathToMappedObjects = dictionary;
    }

    return self;
}

- (NSDictionary *)dictionary
{
    return [self.keyPathToMappedObjects copy];
}

- (NSArray *)array
{
    // Flatten results down into a single array
    NSMutableArray *collection = [NSMutableArray array];
    for (id object in [self.keyPathToMappedObjects allValues]) {
        // We don't want to strip the keys off of a mapped dictionary result
        if (NO == [object isKindOfClass:[NSDictionary class]] && [object respondsToSelector:@selector(allObjects)]) {
            [collection addObjectsFromArray:[object allObjects]];
        } else {
            [collection addObject:object];
        }
    }

    return collection;
}

- (NSSet *)set
{
    return [NSSet setWithArray:[self array]];
}

- (id)firstObject
{
    return [[self array] firstObject];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, results=%@>", NSStringFromClass([self class]), self, self.keyPathToMappedObjects];
}

- (NSUInteger)count
{
    return [[self array] count];
}

@end
