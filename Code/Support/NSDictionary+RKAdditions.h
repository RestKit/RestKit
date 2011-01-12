//
//  NSDictionary+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 9/5/10.
//
//

#import <Foundation/Foundation.h>

@interface NSDictionary (RKAdditions)

/**
 * Creates and initializes a dictionary with key value pairs, with the keys specified
 * first instead of the objects. This allows for a more sensible definition of the 
 * property to element and relationship mappings on RKObjectMappable classes
 */
+ (id)dictionaryWithKeysAndObjects:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;

@end
