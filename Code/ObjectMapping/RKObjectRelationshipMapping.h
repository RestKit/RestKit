//
//  RKObjectRelationshipMapping.h
//  RestKit
//
//  Created by Blake Watters on 5/4/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectAttributeMapping.h"
#import "RKObjectMapping.h"

@interface RKObjectRelationshipMapping : RKObjectAttributeMapping {
    RKObjectMapping* _objectMapping;
}

@property (nonatomic, retain) RKObjectMapping* objectMapping;

+ (RKObjectRelationshipMapping*) mappingFromKeyPath:(NSString*)sourceKeyPath toKeyPath:(NSString*)destinationKeyPath objectMapping:(RKObjectMapping*)objectMapping;

@end
