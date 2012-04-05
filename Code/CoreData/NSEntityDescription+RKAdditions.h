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
@property(nonatomic, retain) NSString *primaryKeyAttribute;

@end
