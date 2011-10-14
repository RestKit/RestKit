//
//  RKObjectMappingProvider.m
//  RestKit
//
//  Created by Jeremy Ellison on 5/6/11.
//  Copyright 2011 RestKit
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

#import "RKObjectMappingProvider.h"

@implementation RKObjectMappingProvider

+ (RKObjectMappingProvider *)objectMappingProvider {
    return [[self new] autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        _objectMappings = [NSMutableArray new];
        _mappingsByKeyPath = [NSMutableDictionary new];
        _serializationMappings = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [_objectMappings release];
    [_mappingsByKeyPath release];
    [_serializationMappings release];
    [super dealloc];
}

- (void)setObjectMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping forKeyPath:(NSString *)keyPath {
    [_mappingsByKeyPath setValue:objectOrDynamicMapping forKey:keyPath];
}

- (void)removeObjectMappingForKeyPath:(NSString *)keyPath {
    [_mappingsByKeyPath removeObjectForKey:keyPath];
}

- (id<RKObjectMappingDefinition>)objectMappingForKeyPath:(NSString *)keyPath {
    return [_mappingsByKeyPath objectForKey:keyPath];
}

- (void)setSerializationMapping:(RKObjectMapping *)mapping forClass:(Class)objectClass {
    [_serializationMappings setValue:mapping forKey:NSStringFromClass(objectClass)];
}

- (RKObjectMapping*)serializationMappingForClass:(Class)objectClass {
    return (RKObjectMapping *)[_serializationMappings objectForKey:NSStringFromClass(objectClass)];
}

- (NSDictionary*)objectMappingsByKeyPath {
    return _mappingsByKeyPath;
}

- (void)registerObjectMapping:(RKObjectMapping *)objectMapping withRootKeyPath:(NSString *)keyPath {
    // TODO: Should generate logs
    objectMapping.rootKeyPath = keyPath;
    [self setMapping:objectMapping forKeyPath:keyPath];
    RKObjectMapping* inverseMapping = [objectMapping inverseMapping];
    inverseMapping.rootKeyPath = keyPath;
    [self setSerializationMapping:inverseMapping forClass:objectMapping.objectClass];
}

- (void)addObjectMapping:(RKObjectMapping *)objectMapping {
    [_objectMappings addObject:objectMapping];
}

- (NSArray *)objectMappingsForClass:(Class)theClass {
    NSMutableArray *mappings = [NSMutableArray array];
    NSArray *mappingsToSearch = [[NSArray arrayWithArray:_objectMappings] arrayByAddingObjectsFromArray:[_mappingsByKeyPath allValues]];
    for (NSObject <RKObjectMappingDefinition> *candidateMapping in mappingsToSearch) {
        if ( ![candidateMapping respondsToSelector:@selector(objectClass)] || [mappings containsObject:candidateMapping])
            continue;
        Class mappedClass = [candidateMapping performSelector:@selector(objectClass)];
        if (mappedClass && [NSStringFromClass(mappedClass) isEqualToString:NSStringFromClass(theClass)]) {
            [mappings addObject:candidateMapping];
        }
    }
    return [NSArray arrayWithArray:mappings];
}

- (RKObjectMapping *)objectMappingForClass:(Class)theClass {
    NSArray* objectMappings = [self objectMappingsForClass:theClass];
    return ([objectMappings count] > 0) ? [objectMappings objectAtIndex:0] : nil;
}

#pragma mark - Aliases

+ (RKObjectMappingProvider *)mappingProvider {
    return [self objectMappingProvider];
}

- (RKObjectMapping *)mappingForKeyPath:(NSString *)keyPath {
    return (RKObjectMapping *) [self objectMappingForKeyPath:keyPath];
}

- (void)setMapping:(RKObjectMapping *)mapping forKeyPath:(NSString *)keyPath {
    [self setObjectMapping:mapping forKeyPath:keyPath];
}

- (NSDictionary *)mappingsByKeyPath {
    return [self objectMappingsByKeyPath];
}

- (void)registerMapping:(RKObjectMapping *)objectMapping withRootKeyPath:(NSString *)keyPath {
    return [self registerObjectMapping:objectMapping withRootKeyPath:keyPath];
}

- (void)removeMappingForKeyPath:(NSString *)keyPath {
    [self removeObjectMappingForKeyPath:keyPath];
}

@end
