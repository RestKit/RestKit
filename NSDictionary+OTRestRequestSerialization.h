//
//  NSDictionary+OTRestRequestSerialization.h
//  OTRestFramework
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRestRequestSerializable.h"

@interface NSDictionary (OTRestRequestSerialization) <OTRestRequestSerializable>

- (NSString*)URLEncodedString;
- (NSString*)ContentTypeHTTPHeader;
- (NSData*)HTTPBody;

@end
