//
//  RKKeyPathConnectionDescription.m
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

#import "RKKeyPathConnectionDescription.h"
#import "RKConnectionDescriptionSubclass.h"

@interface RKKeyPathConnectionDescription ()
@property (nonatomic, copy, readwrite) NSString *keyPath;
@end

@implementation RKKeyPathConnectionDescription

- (id)initWithRelationship:(NSRelationshipDescription *)relationship keyPath:(NSString *)keyPath
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

- (id)findRelatedObjectFor:(NSManagedObject *)managedObject inManagedObjectCache:(id<RKManagedObjectCaching>)managedObjectCache
{
    return [managedObject valueForKeyPath:self.keyPath];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p connecting Relationship '%@' of Entity '%@' with keyPath=%@>",
            NSStringFromClass([self class]), self, [self.relationship name], [[self.relationship entity] name], self.keyPath];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithRelationship:self.relationship keyPath:self.keyPath];
}

@end
