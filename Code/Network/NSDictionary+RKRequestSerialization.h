//
//  NSDictionary+RKRequestSerialization.h
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.

#import <Foundation/Foundation.h>
#import "RKRequestSerializable.h"

/**
 * Extends NSDictionary to enable usage as the params of an RKRequest.
 *
 * This protocol provides a serialization of NSDictionary into a URL
 * encoded string representation. This enables us to provide an NSDictionary
 * as the params argument for an RKRequest.
 *
 * @see RKRequestSerializable
 * @see RKRequest#params
 * @class NSDictionary (RKRequestSerialization)
 */
@interface NSDictionary (RKRequestSerialization) <RKRequestSerializable>

/**
 * Returns a representation of the dictionary as a URLEncoded string
 *
 * @returns A UTF-8 encoded string representation of the keys/values in the dictionary
 */
- (NSString*)URLEncodedString;

@end
