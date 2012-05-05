//
//  RKEntityByAttributeCache.h
//  RestKit
//
//  Created by Blake Watters on 5/1/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

// RKManagedObjectContext
// Maybe RKManagedObjectContextCache | RKEntityCache | RKEntityByAttributeCache
// TODO: Better name... RKEntityAttributeCache ??
@interface RKEntityByAttributeCache : NSObject

///-----------------------------------------------------------------------------
/// @name Creating a Cache
///-----------------------------------------------------------------------------

- (id)initWithEntity:(NSEntityDescription *)entity attribute:(NSString *)attributeName managedObjectContext:(NSManagedObjectContext *)context;

///-----------------------------------------------------------------------------
/// @name Getting Cache Identity
///-----------------------------------------------------------------------------

@property (nonatomic, readonly) NSEntityDescription *entity;
@property (nonatomic, readonly) NSString *attribute;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) BOOL monitorsContextForChanges;

///-----------------------------------------------------------------------------
/// @name Loading and Flushing the Cache
///-----------------------------------------------------------------------------

- (void)load;
- (void)flush;

///-----------------------------------------------------------------------------
/// @name Inspecting Cache State
///-----------------------------------------------------------------------------

- (BOOL)isLoaded;

- (NSUInteger)count;
- (NSUInteger)countWithAttributeValue:(id)attributeValue;

- (BOOL)containsObject:(NSManagedObject *)object;
- (BOOL)containsObjectWithAttributeValue:(id)attributeValue;

// Retrieve the object with the value for the attribute
- (NSManagedObject *)objectWithAttributeValue:(id)attributeValue;
- (NSSet *)objectsWithAttributeValue:(id)attributeValue;

///-----------------------------------------------------------------------------
/// @name Managing Cached Objects
///-----------------------------------------------------------------------------

- (void)addObject:(NSManagedObject *)object;
- (void)removeObject:(NSManagedObject *)object;

@end
