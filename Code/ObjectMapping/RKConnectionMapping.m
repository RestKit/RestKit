//
//  RKConnectionMapping.m
//  RestKit
//
//  Created by Charlie Savage on 5/15/12.
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

#import "RKConnectionMapping.h"
#import "RKEntityMapping.h"
#import "RKObjectManager.h"
#import "RKManagedObjectCaching.h"
#import "RKDynamicMappingMatcher.h"

// Provides support for connecting a relationship by
@interface RKForeignKeyConnectionMapping : RKConnectionMapping
@end

// Provides support for connecting a relationship by traversing the object graph
@interface RKKeyPathConnectionMapping : RKConnectionMapping
@end

@interface RKConnectionMapping ()
@property (nonatomic, strong, readwrite) NSRelationshipDescription *relationship;
@property (nonatomic, strong, readwrite) NSString *sourceKeyPath;
@property (nonatomic, strong, readwrite) NSString *destinationKeyPath;
@property (nonatomic, strong, readwrite) RKDynamicMappingMatcher *matcher;
@end

@implementation RKConnectionMapping

//+ (RKConnectionMapping *)connectionMappingForRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping
//{
//    RKConnectionMapping *mapping = [[self alloc] initWithRelationshipName:relationshipName sourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath mapping:objectOrDynamicMapping matcher:nil];
//    return mapping;
//}
//
//+ (RKConnectionMapping*)connectionMappingForRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping matcher:(RKDynamicMappingMatcher *)matcher
//{
//    RKConnectionMapping *mapping = [[self alloc] initWithRelationshipName:relationshipName sourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath mapping:objectOrDynamicMapping matcher:matcher];
//    return mapping;
//}
//
//- (id)initWithRelationshipName:(NSString *)relationshipName sourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath mapping:(RKMapping *)objectOrDynamicMapping matcher:(RKDynamicMappingMatcher *)matcher
//{
//    self = [super init];
//    if (self) {
//        self.relationshipName = relationshipName;
//        self.sourceKeyPath = sourceKeyPath;
//        self.destinationKeyPath = destinationKeyPath;
//        self.mapping = objectOrDynamicMapping;
//        self.matcher = matcher;
//    }
//    return self;
//}

- (Class)connectionMappingClassForRelationship:(NSRelationshipDescription *)relationship sourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath
{
    NSEntityDescription *sourceEntity = relationship.entity;
    NSEntityDescription *destinationEntity = relationship.destinationEntity;

    if ([[sourceEntity attributesByName] objectForKey:sourceKeyPath] && [[destinationEntity attributesByName] objectForKey:destinationKeyPath]) {
        return [RKForeignKeyConnectionMapping class];
    } else {
        return [RKKeyPathConnectionMapping class];
    }
}

- (id)initWithRelationship:(NSRelationshipDescription *)relationship sourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath matcher:(RKDynamicMappingMatcher *)matcher
{
    NSParameterAssert(relationship);
    NSParameterAssert(sourceKeyPath);
    NSParameterAssert(destinationKeyPath);

    Class connectionClass = [self connectionMappingClassForRelationship:relationship sourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath];
    self = [[connectionClass alloc] init];
    if (self) {
        self.relationship = relationship;
        self.sourceKeyPath = sourceKeyPath;
        self.destinationKeyPath = destinationKeyPath;
        self.matcher = matcher;
    }

    return self;
}

- (id)init
{
    if ([self class] == [RKConnectionMapping class]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. "
                                               "Invoke initWithRelationship:sourceKeyPath:destinationKeyPath:matcher: instead.",
                                               NSStringFromClass([self class])]
                                     userInfo:nil];
    }
    return [super init];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithRelationship:self.relationship
                                                     sourceKeyPath:self.sourceKeyPath
                                                destinationKeyPath:self.destinationKeyPath
                                                           matcher:self.matcher];
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


@implementation RKForeignKeyConnectionMapping

- (BOOL)isForeignKeyConnection
{
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p connecting Relationship '%@' from Entity '%@' with sourceKeyPath=%@ to Destination Entity '%@' with destinationKeyPath=%@>",
            NSStringFromClass([self class]), self, self.relationship.name, self.relationship.entity.name, self.sourceKeyPath,
            self.relationship.destinationEntity.name, self.self.destinationKeyPath];
}

@end

@implementation RKKeyPathConnectionMapping

- (BOOL)isKeyPathConnection
{
    return YES;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p connecting Relationship '%@' of Entity '%@' with keyPath=%@>",
            NSStringFromClass([self class]), self, self.relationship.name, self.relationship.entity.name, self.sourceKeyPath];
}

@end
