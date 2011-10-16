//
//  NSString+RestKit.h
//  RestKit
//
//  Created by Blake Watters on 6/15/11.
//  Copyright 2011 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

/**
 A library of helpful additions to the NSString class to simplify
 common tasks within RestKit
 */
@interface NSString (RestKit)

/**
 Returns a resource path from a dictionary of query parameters URL encoded and appended
 This is a convenience method for constructing a new resource path that includes a query. For example,
 when given a resourcePath of /contacts and a dictionary of parameters containing foo=bar and color=red,
 will return /contacts?foo=bar&amp;color=red
 
 *NOTE* - Assumes that the resource path does not already contain any query parameters.
 @param queryParams A dictionary of query parameters to be URL encoded and appended to the resource path
 @return A new resource path with the query parameters appended
 @see RKPathAppendQueryParams
 */
// TODO: Rename to stringByAppendingQueryDictionary:
- (NSString *)appendQueryParams:(NSDictionary*)queryParams;

/**
 Convenience method for generating a path against the properties of an object. Takes
 a string with property names prefixed with a colon and interpolates the values of
 the properties specified and returns the generated path.
 
 For example, given an 'article' object with an 'articleID' property of 12345
 [@"articles/:articleID" interpolateWithObject:article] would generate @"articles/12345"
 This functionality is the basis for resource path generation in the Router.
 
 @param object The object to interpolate the properties against
 @see RKMakePathWithObject
 @see RKPathMatcher
 */
- (NSString *)interpolateWithObject:(id)object;

/**
 Returns a dictionary of parameter keys and values using UTF-8 encoding given a URL-style query string
 on the receiving object. For example, when given the string /contacts?foo=bar&amp;color=red, 
 this will return a dictionary of parameters containing foo=bar and color=red, excluding the path "/contacts?"
 
 @param receiver A string in the form of @"/object/?sortBy=name", or @"/object/?sortBy=name&amp;color=red"
 @return A new dictionary of query parameters, with keys like 'sortBy' and values like 'name'.
 */
- (NSDictionary *)queryParameters;

/**
 Returns a dictionary of parameter keys and values given a URL-style query string
 on the receiving object. For example, when given the string /contacts?foo=bar&amp;color=red, 
 this will return a dictionary of parameters containing foo=bar and color=red, excludes the path "/contacts?"
 
 This method originally appeared as queryContentsUsingEncoding: in the Three20 project:
 https://github.com/facebook/three20/blob/master/src/Three20Core/Sources/NSStringAdditions.m
 
 @param receiver A string in the form of @"/object/?sortBy=name", or @"/object/?sortBy=name&amp;color=red"
 @param encoding The encoding for to use while parsing the query string.
 @return A new dictionary of query parameters, with keys like 'sortBy' and values like 'name'.
 */
- (NSDictionary *)queryParametersUsingEncoding:(NSStringEncoding)encoding;

/**
 Returns a dictionary of parameter keys and values arrays (if requested) given a URL-style query string
 on the receiving object. For example, when given the string /contacts?foo=bar&amp;color=red, 
 this will return a dictionary of parameters containing foo=[bar] and color=[red], excludes the path "/contacts?"
 
 This method originally appeared as queryContentsUsingEncoding: in the Three20 project:
 https://github.com/facebook/three20/blob/master/src/Three20Core/Sources/NSStringAdditions.m
 
 @param receiver A string in the form of @"/object?sortBy=name", or @"/object?sortBy=name&amp;color=red"
 @param shouldUseArrays If NO, it yields the same results as queryParametersUsingEncoding:, otherwise it creates value arrays instead of value strings.
 @param encoding The encoding for to use while parsing the query string.
 @return A new dictionary of query parameters, with keys like 'sortBy' and value arrays (if requested) like ['name'].
 @see queryParametersUsingEncoding:
 */
- (NSDictionary *)queryParametersUsingArrays:(BOOL)shouldUseArrays encoding:(NSStringEncoding)encoding;

/**
 Returns a URL encoded representation of self. 
 */
- (NSString *)stringByAddingURLEncoding;

/**
 Returns a representation of self with percent URL encoded characters replaced with
 their literal values.
 */
- (NSString *)stringByReplacingURLEncoding;

/**
 Interprets the receiver as a path and returns the MIME Type for the path extension 
 using Core Services.
 
 For example, given a string with the path /Users/blake/Documents/monkey.json we would get 
 @"application/json" as the MIME Type.
 
 @return The expected MIME Type of the resource identified by the path or nil if unknown
 */
- (NSString *)MIMETypeForPathExtension;

@end
