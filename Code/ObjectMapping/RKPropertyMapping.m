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

#import <RestKit/ObjectMapping/RKObjectMapping.h>
#import <RestKit/ObjectMapping/RKPropertyMapping.h>

/**
 For consistency with URI Templates (and most web templating languages in general) we are transitioning
 to using braces "{}" instead of parentheses "()" for denoting the variables in the key paths.
 */
static NSString *RKStringByReplacingUnderscoresWithBraces(NSString *string)
{
    return [[string stringByReplacingOccurrencesOfString:@"(" withString:@"{"] stringByReplacingOccurrencesOfString:@")" withString:@"}"];
}

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
    copy.propertyValueClass = self.propertyValueClass;
    copy.valueTransformer = self.valueTransformer;
    return copy;
}

- (BOOL)isEqualToMapping:(RKPropertyMapping *)otherMapping
{
    return [otherMapping isMemberOfClass:[self class]] &&
            (self.sourceKeyPath == otherMapping.sourceKeyPath || [self.sourceKeyPath isEqual:otherMapping.sourceKeyPath]) &&
            [self.destinationKeyPath isEqual:otherMapping.destinationKeyPath];
}

- (void)setSourceKeyPath:(NSString *)sourceKeyPath
{
    _sourceKeyPath = RKStringByReplacingUnderscoresWithBraces(sourceKeyPath);
}

- (void)setDestinationKeyPath:(NSString *)destinationKeyPath
{
    _destinationKeyPath = RKStringByReplacingUnderscoresWithBraces(destinationKeyPath);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p %@ => %@>", self.class, self, self.sourceKeyPath, self.destinationKeyPath];
}

- (id<RKValueTransforming>)valueTransformer
{
    return _valueTransformer ?: [self.objectMapping valueTransformer];
}

@end
