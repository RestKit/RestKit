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
    NSArray* array = [self objectMappingsForKeyPath:keyPath];
    return [array count] ? [array objectAtIndex:0] : nil;
}

- (NSArray*)objectMappingsForKeyPath:(NSString*)keyPath {
    return (NSArray*)[_objectMappingsByKeyPath objectForKey:keyPath];
}

- (void)setMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath {
    [self setObjectMapping:mapping forKeyPath:keyPath];
}

- (void)setObjectMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath {
    NSMutableArray* array = (NSMutableArray*)[self objectMappingsForKeyPath:keyPath];
    if (!array) {
        array = [NSMutableArray array];
        [_objectMappingsByKeyPath setValue:array forKey:keyPath];
    }
    
    [array addObject:mapping];
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
    NSMutableArray* mappingsToSearch = [NSMutableArray arrayWithArray:_objectMappings];
    
    for (NSMutableArray* array in [_objectMappingsByKeyPath allValues]) {
      [mappingsToSearch addObjectsFromArray:array];
    }
  
    for (RKObjectMapping* objectMapping in mappingsToSearch) {
        if (objectMapping.objectClass == theClass && ![mappings containsObject:objectMapping]) {
            [mappings addObject:objectMapping];
        }
    }
    
    return [NSArray arrayWithArray:mappings];
}

- (RKObjectMapping*)objectMappingForClass:(Class)theClass {
    return [[self objectMappingsForClass:theClass] objectAtIndex:0];
}

@end
