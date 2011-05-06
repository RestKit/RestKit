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

+ (RKObjectRelationshipMapping*) mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath objectMapping:(RKObjectMapping*)objectMapping {
    RKObjectRelationshipMapping* mapping = (RKObjectRelationshipMapping*) [self mappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath];
    mapping.objectMapping = objectMapping;
    return mapping;
}

- (void)dealloc {
    [_objectMapping release];
    [super dealloc];
}

@end
