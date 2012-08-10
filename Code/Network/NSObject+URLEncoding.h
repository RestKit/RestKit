//
//  NSObject+URLEncoding.h
//  RestKit
//
//  Created by Jeff Arena on 7/11/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//


@interface NSObject (URLEncoding)

/**
 * Returns a representation of the object as a URLEncoded string
 *
 * @returns A UTF-8 encoded string representation of the object
 */
- (NSString *)URLEncodedString;

@end
