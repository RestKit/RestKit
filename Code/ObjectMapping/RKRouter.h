//
//  RKRouter.h
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "../Network/Network.h"
#import "RKObjectMappable.h"

/**
 * Defines a protocol for mapping Cocoa objects to remote resource locations and
 * serializables representations.
 */
@protocol RKRouter

/**
 * Returns the resource path to send requests for a given object and HTTP method
 */
- (NSString*)resourcePathForObject:(NSObject<RKObjectMappable>*)object method:(RKRequestMethod)method;

@end
