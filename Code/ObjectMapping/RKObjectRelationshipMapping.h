//
//  RKObjectRelationshipMapping.h
//  RestKit
//
//  Created by Blake Watters on 5/4/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectAttributeMapping.h"

@class RKObjectMapping;

@interface RKObjectRelationshipMapping : RKObjectAttributeMapping {
    RKObjectMapping* _objectMapping;
    BOOL _reversible;
}

@property (nonatomic, retain) RKObjectMapping* objectMapping;
@property (nonatomic, assign) BOOL reversible;

+ (RKObjectRelationshipMapping*) mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath objectMapping:(RKObjectMapping*)objectMapping;

+ (RKObjectRelationshipMapping*) mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath objectMapping:(RKObjectMapping*)objectMapping reversible:(BOOL)reversible;

@end
