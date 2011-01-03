//
//  RKParser.h
//  RestKit
//
//  Created by Blake Watters on 10/1/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

/**
 * A Parser is responsible for transforming a string
 * of data into a dictionary. This allows the model mapper to
 * map properties using key-value coding
 */
@protocol RKParser

/**
 * Return a key-value coding compliant representation of a payload.
 * Object attributes are encoded as a dictionary and collections
 * of objects are returned as arrays.
 */
- (id)objectFromString:(NSString*)string;

- (NSString*)stringFromObject:(id)object;

@end
