//
//  OTRestRequestSerializable.h
//  gateguru
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

/*
 * This protocol is implemented by objects that can be serialized into a representation suitable
 * for transmission over a REST request. Suitable serializations are x-www-form-urlencoded and
 * multipart/form-data.
 */
@protocol OTRestRequestSerializable

/**
 * The value of the Content-Type header for the HTTP Body representation of the serialization
 */
- (NSString*)ContentTypeHTTPHeader;

/**
 * An NSData representing the HTTP Body serialization of the object implementing the protocol
 */
- (NSData*)HTTPBody;

@end
