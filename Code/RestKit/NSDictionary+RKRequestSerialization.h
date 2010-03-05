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

// TODO: Move to new file or rename...
+ (id)dictionaryWithKeysAndObjects:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;
- (id)keyForObject:(id)object;

- (NSString*)URLEncodedString;
- (NSString*)ContentTypeHTTPHeader;
- (NSData*)HTTPBody;

@end
