//
//  NSString+RestKit.h
//  RestKit
//
//  Created by Blake Watters on 6/15/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A library of helpful additions to the NSString class to simplify
 common tasks within RestKit
 */
@interface NSString (NSString)

/**
 Returns a resource path with a dictionary of query parameters URL encoded and appended
 This is a convenience method for constructing a new resource path that includes a query. For example,
 when given a resourcePath of /contacts and a dictionary of parameters containing foo=bar and color=red,
 will return /contacts?foo=bar&color=red
 
 *NOTE* - Assumes that the resource path does not already contain any query parameters.
 @param queryParams A dictionary of query parameters to be URL encoded and appended to the resource path
 @return A new resource path with the query parameters appended
 @see RKPathAppendQueryParams
 */
- (NSString*)appendQueryParams:(NSDictionary*)queryParams;

/**
 Convenience method for generating a path against the properties of an object. Takes
 a string with property names encoded in parentheses and interpolates the values of
 the properties specified and returns the generated path.
 
 For example, given an 'article' object with an 'articleID' property of 12345
 [@"articles/(articleID)" interpolateWithObject:article] would generate @"articles/12345"
 This functionality is the basis for resource path generation in the Router.
 
 @param object The object to interpolate the properties against
 */
- (NSString*)interpolateWithObject:(id)object;

@end
