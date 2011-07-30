//
//  RKObjectRelationshipMapping.h
//  RestKit
//
//  Created by Blake Watters on 5/4/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectAttributeMapping.h"

@class RKObjectAbstractMapping;

@interface RKObjectRelationshipMapping : RKObjectAttributeMapping {
    RKObjectAbstractMapping* _mapping;
    BOOL _reversible;
}

@property (nonatomic, retain) RKObjectAbstractMapping* mapping;
@property (nonatomic, assign) BOOL reversible;

+ (RKObjectRelationshipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(RKObjectAbstractMapping*)objectOrPolymorphicMapping;

+ (RKObjectRelationshipMapping*)mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath withMapping:(RKObjectAbstractMapping*)objectOrPolymorphicMapping reversible:(BOOL)reversible;

@end
