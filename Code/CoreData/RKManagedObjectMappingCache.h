//
//  RKManagedObjectMappingCache.h
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKManagedObjectMapping.h"

@protocol RKManagedObjectMappingCache

/**
 * Retrieves a model object from the object store given a Core Data entity and
 * the primary key attribute and value for the desired object.
 */
- (NSManagedObject *)findInstanceOfEntity:(NSEntityDescription *)entity
                              withMapping:(RKManagedObjectMapping *)mapping
                       andPrimaryKeyValue:(id)primaryKeyValue
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
