//
//  RKObjectRelationshipMapping.m
//  RestKit
//
//  Created by Blake Watters on 5/4/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectRelationshipMapping.h"

@implementation RKObjectRelationshipMapping

@synthesize objectMapping = _objectMapping;
@synthesize reversible = _reversible;

+ (RKObjectRelationshipMapping*) mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath objectMapping:(RKObjectMapping*)objectMapping reversible:(BOOL)reversible {
    RKObjectRelationshipMapping* mapping = (RKObjectRelationshipMapping*) [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath];
    mapping.objectMapping = objectMapping;
    mapping.reversible = reversible;
    return mapping;
}

+ (RKObjectRelationshipMapping*) mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath objectMapping:(RKObjectMapping*)objectMapping {
    RKObjectRelationshipMapping* mapping = [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath objectMapping:objectMapping reversible:YES];
    return mapping;
}

- (id)copyWithZone:(NSZone *)zone {
    RKObjectRelationshipMapping* copy = [super copyWithZone:zone];
    copy.objectMapping = self.objectMapping;
    copy.reversible = self.reversible;
    return copy;
}

- (void)dealloc {
    [_objectMapping release];
    [super dealloc];
}

@end
