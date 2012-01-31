//
//  RKInMemoryEntityCache.h
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKManagedObjectMapping.h"

@interface RKInMemoryEntityCache : NSObject {
    NSMutableDictionary *_entityCache;
}

@property (nonatomic, readonly) NSDictionary *entityCache;

/**
 */
- (NSMutableDictionary *)cachedObjectsForEntity:(NSEntityDescription *)entity
                                    withMapping:(RKManagedObjectMapping *)mapping
                                      inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 */
- (NSManagedObject *)cachedObjectForEntity:(NSEntityDescription *)entity
                               withMapping:(RKManagedObjectMapping *)mapping
                        andPrimaryKeyValue:(id)primaryKeyValue
                                 inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 */
- (void)cacheObjectsForEntity:(NSEntityDescription *)entity
                  withMapping:(RKManagedObjectMapping *)mapping
                    inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 */
- (void)cacheObject:(NSManagedObject *)managedObject
        withMapping:(RKManagedObjectMapping *)mapping
          inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 */
- (void)cacheObject:(NSEntityDescription *)entity
        withMapping:(RKManagedObjectMapping *)mapping
 andPrimaryKeyValue:(id)primaryKeyValue
          inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 */
- (void)expireCacheEntryForObject:(NSManagedObject *)managedObject
                      withMapping:(RKManagedObjectMapping *)mapping
                        inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 */
- (void)expireCacheEntryForEntity:(NSEntityDescription *)entity;

/**
 */
- (BOOL)shouldCoerceAttributeToString:(NSString *)attribute forEntity:(NSEntityDescription *)entity;

/**
 */
- (NSManagedObject *)objectWithID:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)managedObjectContext;

@end
