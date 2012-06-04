//
//  NSEntityDescription+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 3/22/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 The key for retrieving the name of the attribute that acts as
 the primary key from the user info dictionary of the receiving NSEntityDescription.

 **Value**: @"primaryKeyAttribute"
 */
extern NSString * const RKEntityDescriptionPrimaryKeyAttributeUserInfoKey;

/**
 The substitution variable used in predicateForPrimaryKeyAttribute.

 **Value**: @"PRIMARY_KEY_VALUE"
 @see predicateForPrimaryKeyAttribute
 */
extern NSString * const RKEntityDescriptionPrimaryKeyAttributeValuePredicateSubstitutionVariable;

/**
 Provides extensions to NSEntityDescription for various common tasks.
 */
@interface NSEntityDescription (RKAdditions)

/**
 The name of the attribute that acts as the primary key for the receiver.

 The primary key attribute can be configured in two ways:
    1. From within the Xcode Core Data editing view by
 adding the desired attribute's name as the value for the
 key `primaryKeyAttribute` to the user info dictionary.
    1. Programmatically, by retrieving the NSEntityDescription instance and
 setting the property's value.

 Programmatically configured values take precedence over the user info
 dictionary.
 */
@property (nonatomic, retain) NSString *primaryKeyAttributeName;

/**
 The attribute description object for the attribute designated as the primary key for the receiver.
 */
@property (nonatomic, readonly) NSAttributeDescription *primaryKeyAttribute;

/**
 The class representing the value of the attribute designated as the primary key for the receiver.
 */
@property (nonatomic, readonly) Class primaryKeyAttributeClass;

/**
 Returns a cached predicate specifying that the primary key attribute is equal to the $PRIMARY_KEY_VALUE
 substitution variable.

 This predicate is cached to avoid parsing overhead during object mapping operations
 and must be evaluated using [NSPredicate predicateWithSubstitutionVariables:]

 @return A cached predicate specifying the value of the primary key attribute is equal to the $PRIMARY_KEY_VALUE
 substitution variable.
 */
- (NSPredicate *)predicateForPrimaryKeyAttribute;

/**
 Returns a predicate specifying that the value of the primary key attribute is equal to a given
 value. This predicate is constructed by evaluating the cached predicate returned by the
 predicateForPrimaryKeyAttribute with a dictionary of substitution variables specifying that
 $PRIMARY_KEY_VALUE is equal to the given value.

 **NOTE**: This method considers the type of the receiver's primary key attribute when constructing
 the predicate. It will coerce the given value into either an NSString or an NSNumber as
 appropriate. This behavior is a convenience to avoid annoying issues related to Core Data's
 handling of predicates for NSString and NSNumber types that were not appropriately casted.

 @return A predicate speciying that the value of the primary key attribute is equal to a given value.
 */
- (NSPredicate *)predicateForPrimaryKeyAttributeWithValue:(id)value;

/**
 Coerces the given value into the class representing the primary key. Currently support NSString
 and NSNumber coercsions.

 @bug **NOTE** This API is temporary and will be deprecated and replaced.
 @since 0.10.1
 */
- (id)coerceValueForPrimaryKey:(id)primaryKeyValue;

@end
