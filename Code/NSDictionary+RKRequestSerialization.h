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

- (NSString*)URLEncodedString;
- (NSString*)ContentTypeHTTPHeader;
- (NSData*)HTTPBody;

@end
