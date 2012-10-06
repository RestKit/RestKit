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
 The `RKDynamicMappingMatcher` class provides an interface for encapsulating the selection of an object mapping based on the runtime value of a property at a given key path. A matcher object is initialized with a key path, an expected value to be read from the key path, and an object mapping that is to be applied if the match evaluates to `YES`.  When evaluating the match, the matcher invokes `valueForKeyPath:` on the object being matched and compares the value returned with the `expectedValue` via the `RKObjectIsEqualToObject` function.
 
 @see `RKObjectIsEqualToObject()`
 */
// TODO: better name? RKKeyPathMappingMatcher | RKMappingMatcher | RKKeyPathMatcher | RKMatcher | RKValueMatcher | RKPropertyMatcher
@interface RKDynamicMappingMatcher : NSObject

///-----------------------------
/// @name Initializing a Matcher
///-----------------------------

/**
 Initializes the receiver with a given key path, expected value, and an object mapping that applies in the event of a positive match.
 
 @param keyPath The key path to obtain the comparison value from the object being matched via `valueForKeyPath:`.
 @param expectedValue The value that is expected to be read from `keyPath` if there is a match.
 @param objectMapping The object mapping object that applies if the comparison value is equal to the expected value.
 @return The receiver, initialized with the given key path, expected value, and object mapping.
 */
- (id)initWithKeyPath:(NSString *)keyPath expectedValue:(id)expectedValue objectMapping:(RKObjectMapping *)objectMapping;

///-----------------------------
/// @name Initializing a Matcher
///-----------------------------

/**
 The key path to obtain the comparison value from the object being matched via `valueForKeyPath:`.
 */
@property (nonatomic, copy, readonly) NSString *keyPath;

/**
 The value that is expected to be read from `keyPath` if there is a match.
 */
@property (nonatomic, strong, readonly) id expectedValue;

/**
 The object mapping object that applies if the comparison value read from `keyPath` is equal to the `expectedValue`.
 */
@property (nonatomic, strong, readonly) RKObjectMapping *objectMapping;

///-------------------------
/// @name Evaluating a Match
///-------------------------

/**
 Returns a Boolean value that indicates if the given object matches the expectations of the receiver.
 
 The match is evaluated by invoking `valueForKeyPath:` on the give object with the value of the `keyPath` property and comparing the returned value with the `expectedValue` using the `RKObjectIsEqualToObject` function.
 
 @param object The object to be evaluated.
 @return `YES` if the object matches the expectations of the receiver, else `NO`.
 */
- (BOOL)matches:(id)object;

@end
