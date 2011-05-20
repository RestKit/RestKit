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
        _mappings = [NSMutableDictionary new];
        _serializationMappings = [NSMutableDictionary new];
    }
    return self;
}

- (void)dealloc {
    [_mappings release];
    [_serializationMappings release];
    [super dealloc];
}

- (RKObjectMapping*)objectMappingForKeyPath:(NSString*)keyPath {
    return [_mappings objectForKey:keyPath];
}

- (void)setMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath {
    [_mappings setValue:mapping forKey:keyPath];
}

- (void)setMapping:(RKObjectMapping *)mapping forClass:(Class)objectClass {
    [_serializationMappings setValue:mapping forKey:NSStringFromClass(objectClass)];
}

- (RKObjectMapping*)objectMappingForClass:(Class)objectClass {
    return (RKObjectMapping*)[_serializationMappings objectForKey:NSStringFromClass(objectClass)];
}

- (NSDictionary*)objectMappingsByKeyPath {
    return _mappings;
}

- (void)registerMapping:(RKObjectMapping*)objectMapping withRootKeyPath:(NSString*)keyPath {
    // TODO: Should generate logs
    [self setMapping:objectMapping forKeyPath:keyPath];
    RKObjectMapping* inverseMapping = [objectMapping inverseMapping];
    inverseMapping.rootKeyPath = keyPath;
    [self setMapping:inverseMapping forClass:objectMapping.objectClass];
}

@end
