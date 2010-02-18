//
//  RKRequestSerializable.h
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

/*
 * This protocol is implemented by objects that can be serialized into a representation suitable
 * for transmission over a REST request. Suitable serializations are x-www-form-urlencoded and
 * multipart/form-data.
 */
@protocol RKRequestSerializable

/**
 * The value of the Content-Type header for the HTTP Body representation of the serialization
 */
- (NSString*)ContentTypeHTTPHeader;

/**
 * An NSData representing the HTTP Body serialization of the object implementing the protocol
 */
- (NSData*)HTTPBody;

@end
