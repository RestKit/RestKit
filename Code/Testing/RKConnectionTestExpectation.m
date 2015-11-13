//
//  RKConnectionTestExpectation.m
//  RestKit
//
//  Created by Blake Watters on 12/8/12.
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

#ifdef _COREDATADEFINES_H

#import <RestKit/ObjectMapping/RKObjectUtilities.h>
#import <RestKit/Testing/RKConnectionTestExpectation.h>

@interface RKConnectionTestExpectation ()
@property (nonatomic, copy, readwrite) NSString *relationshipName;
@property (nonatomic, copy, readwrite) NSDictionary *attributes;
@property (nonatomic, strong, readwrite) id value;
@end

@implementation RKConnectionTestExpectation

+ (instancetype)expectationWithRelationshipName:(NSString *)relationshipName attributes:(NSDictionary *)attributes value:(id)value
{
    return [[self alloc] initWithRelationshipName:relationshipName attributes:attributes value:value];
}

- (instancetype)initWithRelationshipName:(NSString *)relationshipName attributes:(NSDictionary *)attributes value:(id)value
{
    NSParameterAssert(relationshipName);
    NSAssert(value == nil ||
             [value isKindOfClass:[NSManagedObject class]] ||
             RKObjectIsCollectionContainingOnlyManagedObjects(value), @"Can only expect a connection to `nil`, a `NSManagedObject`, or a collection of `NSManagedObject` objects");
    self = [self init];
    if (self) {
        self.relationshipName = relationshipName;
        self.attributes = attributes;
        self.value = value;
    }
    return self;
}

- (NSString *)summary
{
    return [NSString stringWithFormat:@"connect relationship '%@'", self.relationshipName];
}

- (NSString *)description
{
    NSMutableString *description = [[self summary] mutableCopy];
    if (self.attributes) [description appendFormat:@" using attributes %@", self.attributes];
    if (self.value) [description appendFormat:@" to value %@", self.value];
    return description;
}

@end

#endif
