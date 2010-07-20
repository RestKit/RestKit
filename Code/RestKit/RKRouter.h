//
//  RKRouter.h
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRequest.h"
#import "RKResourceMappable.h"
#import "RKRequestSerializable.h"

/**
 * Defines a protocol for mapping Cocoa objects to remote resource locations and
 * serializables representations.
 */
@protocol RKRouter

/**
 * Returns the remote path to send requests for a given object and HTTP method
 */
- (NSString*)pathForObject:(NSObject<RKResourceMappable>*)resource method:(RKRequestMethod)method;

/**
 * Returns a serialization of an object suitable for exchanging with a remote system
 */
- (NSObject<RKRequestSerializable>*)serializationForObject:(NSObject<RKResourceMappable>*)resource method:(RKRequestMethod)method;

@end
