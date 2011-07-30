//
//  RKObjectAbstractMapping.h
//  RestKit
//
//  Created by Blake Watters on 7/29/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 An abstract superclass for RKObjectMapping and RKObjectPolymorphic mapping.
 Provides type safety checks
 */
@interface RKObjectAbstractMapping : NSObject

- (BOOL)forceCollectionMapping;
- (Class)objectClass;
@end
