//
//  RKPathMatcher.h
//  RestKit
//
//  Created by Greg Combs on 9/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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
@class SOCPattern;

/**
 Convenience method for generating a path against the properties of an object. Takes an `NSString` with property names prefixed with a colon and interpolates the values of the properties specified and returns the generated path.
 
 For example, given an `article` object with an `articleID` property whose value is `@12345`, `RKPathFromPatternWithObject(@"articles/:articleID", article)` would return `@"articles/12345"`.
 
 This functionality is the basis for path generation in the `RKRouter` class.
 
 @param pathPattern An `SOCPattern` string containing zero or more colon-prefixed property names.
 @param object The object to interpolate the properties against
 @return A new `NSString` object with the values of the given object interpolated for the colon-prefixed properties name in the given pattern string.
 @see `RKPathMatcher`
 @see `SOCPattern`
 */
NSString *RKPathFromPatternWithObject(NSString *pathPattern, id object);

/**
 The `RKPathMatcher` class performs pattern matching and parameter parsing of strings, typically representing the path portion of an `NSURL` object. It provides much of the necessary tools to map a given path to local objects (the inverse of RKRouter's function).  This makes it easier to implement the `RKManagedObjectCaching` protocol and generate `NSFetchRequest` objects from a given path.  There are two means of instantiating and using a matcher object in order to provide more flexibility in implementations, and to improve efficiency by eliminating repetitive and costly pattern initializations.

 @see `RKManagedObjectCaching`
 @see `RKPathFromPatternWithObject`
 @see `RKRouter`
 */
@interface RKPathMatcher : NSObject <NSCopying>

///---------------------------------
/// @name Matching Paths to Patterns
///---------------------------------

/**
 Creates a path match object starting from a path string.  This method should be followed by `matchesPattern:tokenizeQueryStrings:parsedArguments:`

 @param pathString The string to evaluate and parse, such as `/districts/tx/upper/?apikey=GC5512354`
 @return An instantiated `RKPathMatcher` without an established pattern.
 */
+ (instancetype)pathMatcherWithPath:(NSString *)pathString;

/**
 Determines if the path string matches the provided pattern, and yields a dictionary with the resulting matched key/value pairs.  Use of this method should be preceded by `pathMatcherWithPath:` Pattern strings should include encoded parameter keys, delimited by a single colon at the beginning of the key name.

 *NOTE 1 *- Numerous colon-encoded parameter keys can be joined in a long pattern, but each key must be separated by at least one unmapped character.  For instance, `/:key1:key2:key3/` is invalid, whereas `/:key1/:key2/:key3/` is acceptable.

 *NOTE 2 *- The pattern matcher supports KVM, so `:key1.otherKey` normally resolves as it would in any other KVM
 situation, ... otherKey is a sub-key on a the object represented by key1.  This presents problems in circumstances where
 you might want to build a pattern like /:filename.json, where the dot isn't intended as a sub-key on the filename, but rather
 part of the json static string.  In these instances, you need to escape the dot with two backslashes, like so:
 /:filename\\.json

 @param patternString The pattern to use for evaluating, such as `/:entityName/:stateID/:chamber/`
 @param shouldTokenize If YES, any query parameters will be tokenized and inserted into the parsed argument dictionary.
 @param arguments A pointer to a dictionary that contains the key/values from the pattern (and parameter) matching.
 @return A boolean value indicating if the path string successfully matched the pattern.
 */
- (BOOL)matchesPattern:(NSString *)patternString tokenizeQueryStrings:(BOOL)shouldTokenize parsedArguments:(NSDictionary **)arguments;

///---------------------------------
/// @name Matching Patterns to Paths
///---------------------------------

/**
 Creates a path matcher object starting from a pattern string.  This method should be followed by `matchesPath:tokenizeQueryStrings:parsedArguments:`.  Patterns should include encoded parameter keys, delimited by a single colon at the beginning of the key name.

 *NOTE 1 *- Numerous colon-encoded parameter keys can be joined in a long pattern, but each key must be separated by at least one unmapped character.  For instance, `/:key1:key2:key3/` is invalid, whereas `/:key1/:key2/:key3/` is acceptable.

 *NOTE 2 *- The pattern matcher supports KVM, so `:key1.otherKey` normally resolves as it would in any other KVM situation, ... otherKey is a sub-key on a the object represented by key1.  This presents problems in circumstances where you might want to build a pattern like `/:filename.json`, where the dot isn't intended as a sub-key on the filename, but rather part of the json static string.  In these instances, you need to escape the dot with two backslashes, like so: `/:filename\\.json`

 @param patternString The pattern to use for evaluating, such as `/:entityName/:stateID/:chamber/`
 @return An instantiated `RKPathMatcher` with an established pattern.
 */
+ (instancetype)pathMatcherWithPattern:(NSString *)patternString;

/**
 Determines if the given path string matches a pattern, and yields a dictionary with the resulting matched key/value pairs.  Use of this method should be preceded by `pathMatcherWithPattern:`.

 @param pathString The string to evaluate and parse, such as `/districts/tx/upper/?apikey=GC5512354`
 @param shouldTokenize If YES, any query parameters will be tokenized and inserted into the parsed argument dictionary.
 @param arguments A pointer to a dictionary that contains the key/values from the pattern (and parameter) matching.
 @return A boolean value indicating if the path string successfully matched the pattern.
 */
- (BOOL)matchesPath:(NSString *)pathString tokenizeQueryStrings:(BOOL)shouldTokenize parsedArguments:(NSDictionary **)arguments;

///----------------------------------
/// @name Creating Paths from Objects
///----------------------------------

/**
 Generates a path by interpolating the properties of the 'object' argument, assuming the existence of a previously specified pattern established via `pathMatcherWithPattern:`.  Otherwise, this method is identical in function to `RKPathFromPatternWithObject` (in fact it is a shortcut for this method).

 For example, given an 'article' object with an 'articleID' property value of 12345 and a code of "This/That"...

     RKPathMatcher *matcher = [RKPathMatcher pathMatcherWithPattern:@"/articles/:articleID/:code"];
     NSString *path = [matcher pathFromObject:article addingEscapes:YES interpolatedParameters:nil];

 ... will produce a 'path' containing the string `@"/articles/12345/This%2FThat"`

 @param object The object containing the properties to interpolate.
 @param addEscapes Conditionally add percent escapes to the interpolated property values
 @param interpolatedParameters On input, a pointer for a dictionary object. When the path pattern of the receiver is interpolated, this pointer is set to a new dictionary object in which the keys correspond to the named parameters within the path pattern and the values are taken from the corresponding keypaths of the interpolated object .
 @return A string with the object's interpolated property values inserted into the receiver's established pattern.
 @see `RKRouter`
 */
- (NSString *)pathFromObject:(id)object addingEscapes:(BOOL)addEscapes interpolatedParameters:(NSDictionary **)interpolatedParameters;

///-------------------------------------------
/// @name Accessing Tokenized Query Parameters
///-------------------------------------------

@property (copy, readonly) NSDictionary *queryParameters;

@end
