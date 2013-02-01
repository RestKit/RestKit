//
//  RKPropertyMapping.m
//  RestKit
//
//  Created by Blake Watters on 8/27/12.
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

#import "RKPropertyMapping.h"

@interface RKPropertyMapping ()
// Synthesize as read/write to allow assignment in `RKObjectMapping`
@property (nonatomic, weak, readwrite) RKObjectMapping *objectMapping;
@property (nonatomic, copy, readwrite) NSString *sourceKeyPath;
@property (nonatomic, copy, readwrite) NSString *destinationKeyPath;
@end

@implementation RKPropertyMapping

- (id)copyWithZone:(NSZone *)zone
{
    RKPropertyMapping *copy = [[[self class] allocWithZone:zone] init];
    copy.sourceKeyPath = self.sourceKeyPath;
    copy.destinationKeyPath = self.destinationKeyPath;
    return copy;
}

- (BOOL)isEqualToMapping:(RKPropertyMapping *)otherMapping
{
    return [otherMapping isMemberOfClass:[self class]] &&
            [self.sourceKeyPath isEqual:otherMapping.sourceKeyPath] &&
            [self.destinationKeyPath isEqual:otherMapping.destinationKeyPath];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p %@ => %@>", self.class, self, self.sourceKeyPath, self.destinationKeyPath];
}

@end
