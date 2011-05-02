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
@synthesize dictionary = _dictionary;
@synthesize objectMapping = _objectMapping;
@synthesize delegate = _delegate;

- (id)initWithObject:(id)object andDictionary:(NSDictionary*)dictionary atKeyPath:(NSString*)keyPath usingObjectMapping:(RKObjectMapping*)objectMapping {
    NSAssert(object != nil, @"Cannot perform a mapping operation without a target object");
    NSAssert(dictionary != nil, @"Cannot perform a mapping operation without elements");
    NSAssert(keyPath != nil, @"Cannot perform a mapping operation without a keyPath context");
    NSAssert(objectMapping != nil, @"Cannot perform a mapping operation without an object mapping to apply");
    
    self = [super init];
    if (self) {
        _object = [object retain];
        _dictionary = [dictionary retain];
        _keyPath = [keyPath retain];
        _objectMapping = [objectMapping retain];
    }
    
    return self;
}

- (void)dealloc {
    [_dictionary release];
    [_keyPath release];
    [_objectMapping release];
    
    [super dealloc];
}

- (NSString*)objectClassName {
    return NSStringFromClass([self.object class]);
}

- (void)performMapping {
    for (NSString* keyPath in [self.dictionary allKeys]) {
        RKObjectElementMapping* elementMapping = [self.objectMapping mappingForElement:keyPath];        
        if (elementMapping) {
            [self.delegate objectMappingOperation:self didFindMapping:elementMapping forKeyPath:keyPath];
            id value = [self.dictionary valueForKeyPath:keyPath];
            // TODO: Handle relationships and collections by evaluating the type of the elementMapping???
            // didSetValue:forKeyPath:fromKeyPath:
            [self.delegate objectMappingOperation:self didSetValue:value forProperty:elementMapping.property];
            [self.object setValue:value forKey:elementMapping.property];
        } else {
            [self.delegate objectMappingOperation:self didNotFindMappingForKeyPath:keyPath];
        }
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectMappingOperation for '%@' object at 'keyPath': %@. Mapping values from dictionary => %@ to object %@ with object mapping %@",
            [self objectClassName], self.keyPath, self.dictionary, self.objectMapping];
}

@end
