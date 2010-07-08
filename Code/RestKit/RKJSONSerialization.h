//
//  RKJSONSerialization.h
//  RestKit
//
//  Created by Blake Watters on 7/8/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRequestSerializable.h"

/**
 * Defines a JSON serialization of an object suitable for submitting
 * to a remote service expecting JSON input.
 */
@interface RKJSONSerialization : NSObject <RKRequestSerializable> {
	NSObject* _object;
}

/**
 * Returns a RestKit JSON serializable representation of object
 */
+ (id)JSONSerializationWithObject:(NSObject*)object;

/**
 * Initialize a serialization with an object
 */
- (id)initWithObject:(NSObject*)object;

@end
