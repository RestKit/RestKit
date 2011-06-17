//
//  RKObjectElementMapping.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectAttributeMapping.h"

@implementation RKObjectAttributeMapping

@synthesize sourceKeyPath = _sourceKeyPath;
@synthesize destinationKeyPath = _destinationKeyPath;

/**
 @private
 */
- (id)initWithSourceKeyPath:(NSString*)sourceKeyPath andDestinationKeyPath:(NSString*)destinationKeyPath {
    NSAssert(sourceKeyPath != nil, @"Cannot define an element mapping an element name to map from");
    NSAssert(destinationKeyPath != nil, @"Cannot define an element mapping without a property to apply the value to");
    self = [super init];
    if (self) {
        _sourceKeyPath = [sourceKeyPath retain];
        _destinationKeyPath = [destinationKeyPath retain];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    RKObjectAttributeMapping* copy = [[[self class] allocWithZone:zone] initWithSourceKeyPath:self.sourceKeyPath andDestinationKeyPath:self.destinationKeyPath];
    return copy;
}

- (void)dealloc {
    [_sourceKeyPath release];
    [_destinationKeyPath release];
    
    [super dealloc];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectKeyPathMapping: %@ => %@", self.sourceKeyPath, self.destinationKeyPath];
}

+ (RKObjectAttributeMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath {
    RKObjectAttributeMapping* mapping = [[self alloc] initWithSourceKeyPath:sourceKeyPath andDestinationKeyPath:destinationKeyPath];
    return [mapping autorelease];
}

@end
