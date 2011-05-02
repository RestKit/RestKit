//
//  RKObjectMapping.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectKeyPathMapping.h"

// Defines the mapping rules for a given target class
@interface RKObjectMapping : NSObject {
    Class _objectClass;
    NSMutableArray* _keyPathMappings;
}

@property (nonatomic, assign) Class objectClass;

+ (RKObjectMapping*)mappingForClass:(Class)objectClass;
- (void)addKeyPathMapping:(RKObjectKeyPathMapping*)mapping;
- (RKObjectKeyPathMapping*)mappingForKeyPath:(NSString*)element;

@end
