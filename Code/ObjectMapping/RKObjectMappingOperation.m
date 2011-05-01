//
//  RKObjectMappingOperation.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMappingOperation.h"

@implementation RKObjectMappingOperation

@synthesize object = _object;
@synthesize keyPath = _keyPath;
@synthesize elements = _elements;
@synthesize objectMapping = _objectMapping;
@synthesize delegate = _delegate;

- (id)initWithObject:(id)object andElements:(NSDictionary*)elements atKeyPath:(NSString*)keyPath usingObjectMapping:(RKObjectMapping*)objectMapping {
    NSAssert(object != nil, @"Cannot perform a mapping operation without a target object");
    NSAssert(elements != nil, @"Cannot perform a mapping operation without elements");
    NSAssert(keyPath != nil, @"Cannot perform a mapping operation without a keyPath context");
    NSAssert(objectMapping != nil, @"Cannot perform a mapping operation without an object mapping to apply");
    
    self = [super init];
    if (self) {
        _object = [object retain];
        _elements = [elements retain];
        _keyPath = [keyPath retain];
        _objectMapping = [objectMapping retain];
    }
    
    return self;
}

- (void)dealloc {
    [_elements release];
    [_keyPath release];
    [_objectMapping release];
    
    [super dealloc];
}

- (NSString*)objectClassName {
    return NSStringFromClass([self.object class]);
}

- (void)performMapping {
    for (NSString* element in [self.elements allKeys]) {
        RKObjectElementMapping* elementMapping = [self.objectMapping mappingForElement:element];        
        if (elementMapping) {
            [self.delegate objectMappingOperation:self didFindMapping:elementMapping forElement:element];
            id value = [self.elements valueForKey:element];
            // TODO: Handle relationships and collections by evaluating the type of the elementMapping???
            [self.delegate objectMappingOperation:self didSetValue:value forProperty:elementMapping.property];
            [self.object setValue:value forKey:elementMapping.property];
        } else {
            [self.delegate objectMappingOperation:self didNotFindMappingForElement:element];
        }
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectMappingOperation for '%@' object at 'keyPath': %@. Mapping values from elements => %@ to object %@ with object mapping %@",
            [self objectClassName], self.keyPath, self.elements, self.objectMapping];
}

@end
