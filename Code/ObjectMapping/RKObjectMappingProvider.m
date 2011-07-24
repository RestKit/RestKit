//
//  RKStaticObjectMappingProvider.m
//  RestKit
//
//  Created by Jeremy Ellison on 5/6/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMappingProvider.h"

@implementation RKObjectMappingProvider

- (id)init {
    if ((self = [super init])) {
        _objectMappings = [NSMutableArray new];
        _objectMappingsByKeyPath = [NSMutableDictionary new];
        _serializationMappings = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [_objectMappings release];
    [_objectMappingsByKeyPath release];
    [_serializationMappings release];
    [super dealloc];
}

- (RKObjectMapping*)objectMappingForKeyPath:(NSString*)keyPath {
    return [_objectMappingsByKeyPath objectForKey:keyPath];
}

- (void)setMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath {
    [_objectMappingsByKeyPath setValue:mapping forKey:keyPath];
}

- (void)setObjectMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath {
    [_objectMappingsByKeyPath setValue:mapping forKey:keyPath];
}

- (void)setSerializationMapping:(RKObjectMapping *)mapping forClass:(Class)objectClass {
    [_serializationMappings setValue:mapping forKey:NSStringFromClass(objectClass)];
}

- (RKObjectMapping*)serializationMappingForClass:(Class)objectClass {
    return (RKObjectMapping*)[_serializationMappings objectForKey:NSStringFromClass(objectClass)];
}

- (NSDictionary*)objectMappingsByKeyPath {
    return _objectMappingsByKeyPath;
}

- (void)registerMapping:(RKObjectMapping*)objectMapping withRootKeyPath:(NSString*)keyPath {
    // TODO: Should generate logs
    objectMapping.rootKeyPath = keyPath;
    [self setObjectMapping:objectMapping forKeyPath:keyPath];
    RKObjectMapping* inverseMapping = [objectMapping inverseMapping];
    inverseMapping.rootKeyPath = keyPath;
    [self setSerializationMapping:inverseMapping forClass:objectMapping.objectClass];
}

- (void)addObjectMapping:(RKObjectMapping*)objectMapping {
    [_objectMappings addObject:objectMapping];
}

- (NSArray*)objectMappingsForClass:(Class)theClass {
    NSMutableArray* mappings = [NSMutableArray array];
    NSArray* mappingsToSearch = [[NSArray arrayWithArray:_objectMappings] arrayByAddingObjectsFromArray:[_objectMappingsByKeyPath allValues]];
    for (RKObjectMapping* objectMapping in mappingsToSearch) {
        if (objectMapping.objectClass == theClass && ![mappings containsObject:objectMapping]) {
            [mappings addObject:objectMapping];
        }
    }
    
    return [NSArray arrayWithArray:mappings];
}

- (RKObjectMapping*)objectMappingForClass:(Class)theClass {
    NSArray* objectMappings = [self objectMappingsForClass:theClass];
    return ([objectMappings count] > 0) ? [objectMappings objectAtIndex:0] : nil;
}

@end
