//
//  RKObjectMapping.h
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectElementMapping.h"

// Defines the mapping rules for a given target class
@interface RKObjectMapping : NSObject {
    Class _objectClass;
    NSMutableArray* _elementMappings;
}

@property (nonatomic, assign) Class objectClass;

+ (RKObjectMapping*)mappingForClass:(Class)objectClass;
- (void)addElementMapping:(RKObjectElementMapping*)elementMapping;
- (RKObjectElementMapping*)mappingForElement:(NSString*)element;

@end
