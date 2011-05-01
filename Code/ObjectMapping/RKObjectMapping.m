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
        _elementMappings = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc {
    [_elementMappings release];
    [super dealloc];
}

- (void)addElementMapping:(RKObjectElementMapping*)elementMapping {
    NSAssert1([_elementMappings containsObject:elementMapping] == NO, @"Unable to add mapping for element %@, one already exists...", elementMapping.element);
    // TODO: Assert that there is only one mapping per element
    [_elementMappings addObject:elementMapping];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectMapping class => %@: element mappings => %@", NSStringFromClass(self.objectClass), _elementMappings];
}

- (RKObjectElementMapping*)mappingForElement:(NSString*)element {
    for (RKObjectElementMapping* elementMapping in _elementMappings) {
        if ([elementMapping.element isEqualToString:element]) {
            return elementMapping;
        }
    }
    
    return nil;
}

@end
