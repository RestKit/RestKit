//
//  RKDynamicMappingMatcher.h
//  RestKit
//
//  Created by Jeff Arena on 8/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectMapping.h"

/**
 The `RKObjectMappingMatcher` class provides an interface for encapsulating the selection of an object mapping based on runtime values. Matcher objects may be configured by key path and expected value or with a predicate object.

 ## Key Path Matching

 A key path matcher object is initialized with a key path, an expected value to be read from the key path, and an object mapping that is to be applied if the match evaluates to `YES`.  When evaluating the match, the matcher invokes `valueForKeyPath:` on the object being matched and compares the value returned with the `expectedValue` via the `RKObjectIsEqualToObject` function. This provides a flexible, semantic match of the property value.

 ## Predicate Matching

 A predicate matcher object is initialized with a predicate object and an object mapping that is to be applied if the predicate evaluates to `YES` for the object being matched.
 */
@interface RKObjectMappingMatcher : NSObject

///-------------------------------------
/// @name Constructing Key Path Matchers
///-------------------------------------

/**
 Creates and returns a key path matcher object with a given key path, expected value, and an object mapping that applies in the event of a positive match.

 @param keyPath The key path to obtain the comparison value from the object being matched via `valueForKeyPath:`.
 @param expectedValue The value that is expected to be read from `keyPath` if there is a match.
 @param objectMapping The object mapping object that applies if the comparison value is equal to the expected value.
 @return The receiver, initialized with the given key path, expected value, and object mapping.
 */
+ (instancetype)matcherWithKeyPath:(NSString *)keyPath expectedValue:(id)expectedValue objectMapping:(RKObjectMapping *)objectMapping;

///--------------------------------------
/// @name Constructing Predicate Matchers
///--------------------------------------

/**
 Creates and returns a predicate matcher object with a given predicate and an object mapping that applies in the predicate evaluates positively.

 @param predicate The predicate with which to evaluate the matched object.
 @param objectMapping The object mapping object that applies if the predicate evaluates positively for the matched object.
 @return The receiver, initialized with the given key path, expected value, and object mapping.
 */
+ (instancetype)matcherWithPredicate:(NSPredicate *)predicate objectMapping:(RKObjectMapping *)objectMapping;

///-----------------------------------
/// @name Accessing the Object Mapping
///-----------------------------------

/**
 The object mapping object that applies when the receiver matches a given object.

 @see `matches:`
 */
@property (nonatomic, strong, readonly) RKObjectMapping *objectMapping;

///-------------------------
/// @name Evaluating a Match
///-------------------------

/**
 Returns a Boolean value that indicates if the given object matches the expectations of the receiver.

 @param object The object to be evaluated.
 @return `YES` if the object matches the expectations of the receiver, else `NO`.
 */
- (BOOL)matches:(id)object;

@end
