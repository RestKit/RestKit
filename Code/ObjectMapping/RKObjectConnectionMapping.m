//
//  RKObjectConnectionMapping.m
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

#import "RKObjectConnectionMapping.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectMapping.h"
#import "RKObjectManager.h"
#import "RKManagedObjectCaching.h"
#import "RKDynamicObjectMappingMatcher.h"

@interface RKObjectConnectionMapping()
@property (nonatomic, retain) NSString * sourceKeyPath;
@property (nonatomic, retain) NSString * destinationKeyPath;
@property (nonatomic, retain) RKObjectMappingDefinition * mapping;
@property (nonatomic, retain) RKDynamicObjectMappingMatcher* matcher;
@end

@implementation RKObjectConnectionMapping

@synthesize sourceKeyPath;
@synthesize destinationKeyPath;
@synthesize mapping;
@synthesize matcher;

+ (RKObjectConnectionMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(RKObjectMappingDefinition *)objectOrDynamicMapping {
    RKObjectConnectionMapping *mapping = [[self alloc] initFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath matcher:nil withMapping:objectOrDynamicMapping];
    return [mapping autorelease];
}

+ (RKObjectConnectionMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath matcher:(RKDynamicObjectMappingMatcher *)matcher withMapping:(RKObjectMappingDefinition *)objectOrDynamicMapping {
    RKObjectConnectionMapping *mapping = [[self alloc] initFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath matcher:matcher withMapping:objectOrDynamicMapping];
    return [mapping autorelease];
}

- (id)initFromKeyPath:(NSString*)aSourceKeyPath toKeyPath:(NSString*)aDestinationKeyPath matcher:(RKDynamicObjectMappingMatcher *)aMatcher withMapping:(RKObjectMappingDefinition *)aObjectOrDynamicMapping {
    self = [super init];
    self.sourceKeyPath = aSourceKeyPath;
    self.destinationKeyPath = aDestinationKeyPath;
    self.mapping = aObjectOrDynamicMapping;
    self.matcher = aMatcher;
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initFromKeyPath:self.sourceKeyPath toKeyPath:self.destinationKeyPath matcher:self.matcher withMapping:mapping];
}

- (void)dealloc {
    self.sourceKeyPath = nil;
    self.destinationKeyPath = nil;
    self.mapping = nil;
    self.matcher = nil;
    [super dealloc];
}

- (BOOL)isToMany:(NSString *)relationshipName source:(NSManagedObject *)source {
    NSEntityDescription *entity = [source entity];
    NSDictionary *relationships = [entity relationshipsByName];
    NSRelationshipDescription *relationship = [relationships objectForKey:relationshipName];
    return relationship.isToMany;
}

- (NSManagedObject*)findOneConnected:(NSManagedObject *)source sourceValue:(id)sourceValue  {
    RKManagedObjectMapping* objectMapping = (RKManagedObjectMapping *)self.mapping;
    NSObject<RKManagedObjectCaching> *cache = [[objectMapping objectStore] cacheStrategy];
    NSManagedObjectContext *context = [[objectMapping objectStore] managedObjectContextForCurrentThread];
    return [cache findInstanceOfEntity:objectMapping.entity withPrimaryKeyAttribute:self.destinationKeyPath value:sourceValue inManagedObjectContext:context];
}

- (NSMutableSet*)findAllConnected:(NSManagedObject *)source sourceValue:(id)sourceValue {
    NSMutableSet *result = [NSMutableSet set];

    if ([sourceValue conformsToProtocol:@protocol(NSFastEnumeration)]) {
        for (id value in sourceValue) {
            id searchResult = [self findOneConnected:source sourceValue:value];
            if (searchResult) {
                [result addObject:searchResult];
            }
        }
    }
    else {
        id searchResult = [self findOneConnected:source sourceValue:sourceValue];
        if (searchResult) {
            [result addObject:searchResult];
        }
    }
    return result;
}

- (BOOL)checkMatcher:(NSManagedObject *)source {
    if (!matcher) {
        return YES;
    }
    else {
        return [matcher isMatchForData:source];
    }
}

- (id)findConnected:(NSString *)relationshipName source:(NSManagedObject *)source {
    if ([self checkMatcher:source])
    {
        BOOL isToMany = [self isToMany:relationshipName source:source];
        id sourceValue = [source valueForKey:self.sourceKeyPath];
        if (isToMany) {
            return [self findAllConnected:source sourceValue:sourceValue];
        }
        else {
            return [self findOneConnected:source sourceValue:sourceValue];
        }
    }
    else {
        return nil;
    }
}
@end
