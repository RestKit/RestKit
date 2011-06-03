//
//  RKObjectFactory.h
//  RestKit
//
//  Created by Blake Watters on 5/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapping.h"

/**
 Defines a protocol for the creation of objects during an
 object mapping operation. Used to initialize objects that
 are going to be subsequently mapped with an object mapping
 */
@protocol RKObjectFactory <NSObject>

/**
 Return a new initialized, auto-released object with the specified object mapping.
 */
- (id)objectWithMapping:(RKObjectMapping*)objectMapping andData:(id)mappableData;

@end
