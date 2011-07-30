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

- (void)setMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath {
    [_mappingsByKeyPath setValue:mapping forKey:keyPath];
}

- (RKObjectAbstractMapping*)mappingForKeyPath:(NSString*)keyPath {
    return [_mappingsByKeyPath objectForKey:keyPath];
}

- (void)setSerializationMapping:(RKObjectMapping *)mapping forClass:(Class)objectClass {
    [_serializationMappings setValue:mapping forKey:NSStringFromClass(objectClass)];
}

- (RKObjectMapping*)serializationMappingForClass:(Class)objectClass {
    return (RKObjectMapping*)[_serializationMappings objectForKey:NSStringFromClass(objectClass)];
}

- (NSDictionary*)mappingsByKeyPath {
    return _mappingsByKeyPath;
}

- (void)registerMapping:(RKObjectMapping*)objectMapping withRootKeyPath:(NSString*)keyPath {
    // TODO: Should generate logs
    objectMapping.rootKeyPath = keyPath;
    [self setMapping:objectMapping forKeyPath:keyPath];
    RKObjectMapping* inverseMapping = [objectMapping inverseMapping];
    inverseMapping.rootKeyPath = keyPath;
    [self setSerializationMapping:inverseMapping forClass:objectMapping.objectClass];
}

- (void)addObjectMapping:(RKObjectMapping*)objectMapping {
    [_objectMappings addObject:objectMapping];
}

- (NSArray*)objectMappingsForClass:(Class)theClass {
    NSMutableArray* mappings = [NSMutableArray array];
    NSArray* mappingsToSearch = [[NSArray arrayWithArray:_objectMappings] arrayByAddingObjectsFromArray:[_mappingsByKeyPath allValues]];
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

#pragma mark - Deprecated

- (RKObjectMapping*)objectMappingForKeyPath:(NSString*)keyPath {
    return (RKObjectMapping*) [self mappingForKeyPath:keyPath];
}

- (void)setObjectMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath {
    [self setMapping:mapping forKeyPath:keyPath];
}

- (NSDictionary*)objectMappingsByKeyPath {
    return [self mappingsByKeyPath];
}

@end
