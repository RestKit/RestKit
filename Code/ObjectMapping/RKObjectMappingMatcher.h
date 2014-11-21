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
 
 Alternatively, a key path matcher object can be initialized with an expected class instead. When evaluating the match, the matcher invokes `valueForKeyPath:` on the object being matched and compares the value returned with the `expectedClass` via the `isSubclassOfClass:` method. This provides a flexible, semantic match of the property value class.

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

/**
 Creates and returns a key path matcher object with a given key path, expected class, and an object mapping that applies in the event of a positive match.
 
 @param keyPath The key path to obtain the comparison value from the object being matched via `valueForKeyPath:`.
 @param expectedClass The Class that is expected to be read from `keyPath` if there is a match.
 @param objectMapping The object mapping object that applies if the comparison value is equal to the expected value.
 @return The receiver, initialized with the given key path, expected value, and object mapping.
 */
+ (instancetype)matcherWithKeyPath:(NSString *)keyPath expectedClass:(Class)expectedClass objectMapping:(RKObjectMapping *)objectMapping;

/**
 Creates and returns a key path matcher object with a given key path, and a map of expected values to associated RKObjectMapping objects that applies in the event of a positive match with its associated value.  This method can evaluate the keyPath once
 
 @param keyPath The key path to obtain the comparison value from the object being matched via `valueForKeyPath:`.
 @param expectedValue The value that is expected to be read from `keyPath` if there is a match.
 @param objectMapping The object mapping object that applies if the comparison value is equal to the expected value.
 @return The receiver, initialized with the given key path and expected value map.
 */
+ (instancetype)matcherWithKeyPath:(NSString *)keyPath expectedValueMap:(NSDictionary *)valueToObjectMapping;

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


/**
 Creates and returns a matcher object with a given block which returns the RKObjectMapping instance to use, and an optional array of possible object mappings which could be returned.
 
 @param possibleMappings The list of known possible RKObjectMapping instances which could be returned.  This is used to aid RKDynamicMapping's -objectMappings method which is used in some instances, but is not required for mapping.  The block could return a new instance if needed.
 @param block The block with which to evaluate the matched object, and return the object mapping to use.  Return nil if no match (i.e. a `NO` return from the `-matches:` method).
 @return The receiver, initialized with the given block ans possible mappings.
 */
+ (instancetype)matcherWithPossibleMappings:(NSArray *)mappings block:(RKObjectMapping *(^)(id representation))block;

///-----------------------------------
/// @name Accessing the Object Mapping
///-----------------------------------

/**
 Returns the list of all known RKObjectMapping instances which could be returned from this matcher.  This is called when added to or removed from an RKDynamicMapping, and is used to populate the `objectMappings` property there.  The default implementation returns the single value set in the `objectMapping` property, so if that is the only possibility then this method does not need to be overridden.
 */
@property (nonatomic, readonly) NSArray *possibleObjectMappings;

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
