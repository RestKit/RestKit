//
//  RKObjectMapping.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapping.h"

@implementation RKObjectMapping

@synthesize objectClass = _objectClass;

+ (RKObjectMapping*)mappingForClass:(Class)objectClass {
    RKObjectMapping* mapping = [RKObjectMapping new];
    mapping.objectClass = objectClass;    
    return [mapping autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        _keyPathMappings = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc {
    [_keyPathMappings release];
    [super dealloc];
}

- (void)addAttributeMapping:(RKObjectAttributeMapping*)mapping {
    NSAssert1([_keyPathMappings containsObject:mapping] == NO, @"Unable to add mapping for keyPath %@, one already exists...", mapping.sourceKeyPath);
    [_keyPathMappings addObject:mapping];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectMapping class => %@: keyPath mappings => %@", NSStringFromClass(self.objectClass), _keyPathMappings];
}

- (RKObjectAttributeMapping*)mappingForKeyPath:(NSString*)keyPath {
    for (RKObjectAttributeMapping* mapping in _keyPathMappings) {
        if ([mapping.sourceKeyPath isEqualToString:keyPath]) {
            return mapping;
        }
    }
    
    return nil;
}

@end
