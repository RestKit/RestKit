//
//  RKConnectionDescription.m
//  RestKit
//
//  Created by Blake Watters on 11/20/12.
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

#import "RKConnectionDescription.h"

static NSSet *RKSetWithInvalidAttributesForEntity(NSArray *attributes, NSEntityDescription *entity)
{
    NSMutableSet *attributesSet = [NSMutableSet setWithArray:attributes];
    NSSet *validAttributeNames = [NSSet setWithArray:[[entity attributesByName] allKeys]];
    [attributesSet minusSet:validAttributeNames];
    return attributesSet;
}

// Provides support for connecting a relationship by
@interface RKForeignKeyConnectionDescription : RKConnectionDescription
@end

// Provides support for connecting a relationship by traversing the object graph
@interface RKKeyPathConnectionDescription : RKConnectionDescription
@end

@interface RKConnectionDescription ()
@property (nonatomic, strong, readwrite) NSRelationshipDescription *relationship;
@property (nonatomic, copy, readwrite) NSDictionary *attributes;
@property (nonatomic, copy, readwrite) NSString *keyPath;
@end

@implementation RKConnectionDescription

- (instancetype)initWithRelationship:(NSRelationshipDescription *)relationship attributes:(NSDictionary *)attributes
{
    NSParameterAssert(relationship);
    NSParameterAssert(attributes);
    if (! [attributes count]) [NSException raise:NSInvalidArgumentException format:@"Cannot connect a relationship without at least one pair of attributes describing the connection"];
    NSSet *invalidSourceAttributes = RKSetWithInvalidAttributesForEntity([attributes allKeys], [relationship entity]);
    if ([invalidSourceAttributes count]) [NSException raise:NSInvalidArgumentException format:@"Cannot connect relationship: invalid attributes given for source entity '%@': %@", [[relationship entity] name], [[invalidSourceAttributes allObjects] componentsJoinedByString:@", "]];
    NSSet *invalidDestinationAttributes = RKSetWithInvalidAttributesForEntity([attributes allValues], [relationship destinationEntity]);
    if ([invalidDestinationAttributes count]) [NSException raise:NSInvalidArgumentException format:@"Cannot connect relationship: invalid attributes given for destination entity '%@': %@", [[relationship destinationEntity] name], [[invalidDestinationAttributes allObjects] componentsJoinedByString:@", "]];
    
    self = [[RKForeignKeyConnectionDescription alloc] init];
    if (self) {
        self.relationship = relationship;
        self.attributes = attributes;
        self.includesSubentities = YES;
    }
    return self;
}

- (instancetype)initWithRelationship:(NSRelationshipDescription *)relationship keyPath:(NSString *)keyPath
{
    NSParameterAssert(relationship);
    NSParameterAssert(keyPath);
    self = [[RKKeyPathConnectionDescription alloc] init];
    if (self) {
        self.relationship = relationship;
        self.keyPath = keyPath;
    }
    return self;
}

- (instancetype)init
{
    if ([self class] == [RKConnectionDescription class]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. "
                                               "Invoke initWithRelationship:attributes: instead.",
                                               NSStringFromClass([self class])]
                                     userInfo:nil];
    }
    return [super init];
}

- (id)copyWithZone:(NSZone *)zone
{
    if ([self isForeignKeyConnection]) {
        return [[[self class] allocWithZone:zone] initWithRelationship:self.relationship attributes:self.attributes];
    } else if ([self isKeyPathConnection]) {
        return [[[self class] allocWithZone:zone] initWithRelationship:self.relationship keyPath:self.keyPath];
    }
    
    return nil;
}

- (BOOL)isForeignKeyConnection
{
    return NO;
}

- (BOOL)isKeyPathConnection
{
    return NO;
}

@end

@implementation RKForeignKeyConnectionDescription

- (BOOL)isForeignKeyConnection
{
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p connecting Relationship '%@' from Entity '%@' to Destination Entity '%@' with attributes=%@>",
            NSStringFromClass([self class]), self, [self.relationship name], [[self.relationship entity] name],
            [[self.relationship destinationEntity] name], self.attributes];
}

@end

@implementation RKKeyPathConnectionDescription

- (BOOL)isKeyPathConnection
{
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p connecting Relationship '%@' of Entity '%@' with keyPath=%@>",
            NSStringFromClass([self class]), self, [self.relationship name], [[self.relationship entity] name], self.keyPath];
}

@end
