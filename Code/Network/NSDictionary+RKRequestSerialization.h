//
//  NSDictionary+RKRequestSerialization.h
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKRequestSerializable.h"

@interface NSDictionary (RKRequestSerialization) <RKRequestSerializable>

/**
 * Returns a representation of the dictionary as a URLEncoded string
 */
- (NSString*)URLEncodedString;

@end
