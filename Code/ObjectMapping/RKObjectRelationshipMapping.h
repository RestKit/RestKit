//
//  RKObjectRelationshipMapping.h
//  RestKit
//
//  Created by Blake Watters on 5/4/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectAttributeMapping.h"
#import "RKObjectMappingDefinition.h"

@class RKObjectmapping;

@interface RKObjectRelationshipMapping : RKObjectAttributeMapping {
    id<RKObjectMappingDefinition> _mapping;
    BOOL _reversible;
}

@property (nonatomic, retain) id<RKObjectMappingDefinition> mapping;
@property (nonatomic, assign) BOOL reversible;

+ (RKObjectRelationshipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping;

+ (RKObjectRelationshipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(id<RKObjectMappingDefinition>)objectOrDynamicMapping reversible:(BOOL)reversible;

@end
