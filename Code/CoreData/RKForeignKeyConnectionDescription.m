//
//  RKForeignKeyConnectionDescription.m
//  RestKit
//
//  Created by Marius Rackwitz on 21.01.13.
//  Copyright (c) 2013 RestKit. All rights reserved.
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

#import "RKForeignKeyConnectionDescription.h"
#import "RKConnectionDescriptionSubclass.h"
#import "RKLog.h"

static NSSet *RKSetWithInvalidAttributesForEntity(NSArray *attributes, NSEntityDescription *entity)
{
    NSMutableSet *attributesSet = [NSMutableSet setWithArray:attributes];
    NSSet *validAttributeNames = [NSSet setWithArray:[[entity attributesByName] allKeys]];
    [attributesSet minusSet:validAttributeNames];
    return attributesSet;
}

static BOOL RKConnectionAttributeValuesIsNotConnectable(NSDictionary *attributeValues)
{
    return [[NSSet setWithArray:[attributeValues allValues]] isEqualToSet:[NSSet setWithObject:[NSNull null]]];
}

@interface RKForeignKeyConnectionDescription ()
@property (nonatomic, copy, readwrite) NSDictionary *attributes;
@end

@implementation RKForeignKeyConnectionDescription

- (id)initWithRelationship:(NSRelationshipDescription *)relationship attributes:(NSDictionary *)attributes
{
    NSParameterAssert(relationship);
    NSParameterAssert(attributes);
    NSAssert([attributes count], @"Cannot connect a relationship without at least one pair of attributes describing the connection");
    NSSet *invalidSourceAttributes = RKSetWithInvalidAttributesForEntity([attributes allKeys], [relationship entity]);
    NSAssert([invalidSourceAttributes count] == 0, @"Cannot connect relationship: invalid attributes given for source entity '%@': %@", [[relationship entity] name], [[invalidSourceAttributes allObjects] componentsJoinedByString:@", "]);
    NSSet *invalidDestinationAttributes = RKSetWithInvalidAttributesForEntity([attributes allValues], [relationship destinationEntity]);
    NSAssert([invalidDestinationAttributes count] == 0, @"Cannot connect relationship: invalid attributes given for destination entity '%@': %@", [[relationship destinationEntity] name], [[invalidDestinationAttributes allObjects] componentsJoinedByString:@", "]);
    
    self = [[RKForeignKeyConnectionDescription alloc] init];
    if (self) {
        self.relationship = relationship;
        self.attributes = attributes;
        self.includesSubentities = YES;
    }
    return self;
}

- (NSDictionary *)attributeValuesWithObject:(NSManagedObject *)managedObject
{
    NSMutableDictionary *destinationEntityAttributeValues = [NSMutableDictionary dictionaryWithCapacity:[self.attributes count]];
    for (NSString *sourceAttribute in self.attributes) {
        NSString *destinationAttribute = [self.attributes objectForKey:sourceAttribute];
        id sourceValue = [managedObject valueForKey:sourceAttribute];
        [destinationEntityAttributeValues setValue:sourceValue ?: [NSNull null] forKey:destinationAttribute];
    }
    return RKConnectionAttributeValuesIsNotConnectable(destinationEntityAttributeValues) ? nil : destinationEntityAttributeValues;
}


- (id)findRelatedObjectFor:(NSManagedObject *)managedObject inManagedObjectCache:(id<RKManagedObjectCaching>)managedObjectCache
{
    NSDictionary *attributeValues = [self attributeValuesWithObject:managedObject];
    // If there are no attribute values available for connecting, skip the connection entirely
    if (! attributeValues) {
        return nil;
    }
    NSSet *managedObjects = [managedObjectCache managedObjectsWithEntity:[self.relationship destinationEntity]
                                                         attributeValues:attributeValues
                                                  inManagedObjectContext:managedObject.managedObjectContext];
    if (self.destinationPredicate) managedObjects = [managedObjects filteredSetUsingPredicate:self.destinationPredicate];
    if (!self.includesSubentities) managedObjects = [managedObjects filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"entity == %@", [self.relationship destinationEntity]]];
    if ([self.relationship isToMany]) {
        return managedObjects;
    } else {
        if ([managedObjects count] > 1) RKLogWarning(@"Retrieved %ld objects satisfying connection criteria for one-to-one relationship connection: only object will be connected.", (long) [managedObjects count]);
        if ([managedObjects count]) {
            return [managedObjects anyObject];
        }
    }
    
    return nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p connecting Relationship '%@' from Entity '%@' to Destination Entity '%@' with attributes=%@>",
            NSStringFromClass([self class]), self, [self.relationship name], [[self.relationship entity] name],
            [[self.relationship destinationEntity] name], self.attributes];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithRelationship:self.relationship attributes:self.attributes];
}

@end
