//
//  RKEntityIdentifier.h
//  RestKit
//
//  Created by Blake Watters on 11/20/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString * const RKEntityIdentifierUserInfoKey;

@class RKManagedObjectStore;

// RKEntityIdentifier | RKManagedObjectIdentifier | RKEntityIdentity | RKResourceIdentity | RKEntityKey | RKIdentifier
@interface RKEntityIdentifier : NSObject

@property (nonatomic, strong, readonly) NSEntityDescription *entity;
@property (nonatomic, copy, readonly) NSArray *attributes;

// Convenience method
// identifierWithEntityName:???
// entityIdentifierWithName:
+ (id)identifierWithEntityName:(NSString *)entityName attributes:(NSArray *)attributes inManagedObjectStore:(RKManagedObjectStore *)managedObjectStore;

// Designated initializer
- (id)initWithEntity:(NSEntityDescription *)entity attributes:(NSArray *)attributes;

// Optional predicate for filtering matches
@property (nonatomic, copy) NSPredicate *predicate;

///-------------------------------------------
/// @name Inferring Identifiers from the Model
///-------------------------------------------

// NOTE: Add not about checking the entity's userInfo
+ (RKEntityIdentifier *)inferredIdentifierForEntity:(NSEntityDescription *)entity;

@end
