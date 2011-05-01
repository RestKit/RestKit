//
//  RKObjectElementMapping.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectElementMapping.h"

@implementation RKObjectElementMapping

@synthesize element = _element;
@synthesize property = _property;

/*!
 @private
 */
- (id)initWithElement:(NSString*)element andProperty:(NSString*)property {
    NSAssert(element != nil, @"Cannot define an element mapping an element name to map from");
    NSAssert(property != nil, @"Cannot define an element mapping without a property to apply the value to");
    self = [super init];
    if (self) {
        _element = [element retain];
        _property = [property retain];
    }
    
    return self;
}

- (void)dealloc {
    [_element release];
    [_property release];
    
    [super dealloc];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectElementMapping: %@ => %@", self.element, self.property];
}

+ (RKObjectElementMapping*)mappingFromElement:(NSString*)element toProperty:(NSString*)property {
    RKObjectElementMapping* mapping = [[RKObjectElementMapping alloc] initWithElement:element andProperty:property];    
    return [mapping autorelease];
}

@end
