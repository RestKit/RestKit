//
//  RKFetchRequestMappingCache.m
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKFetchRequestMappingCache.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@implementation RKFetchRequestMappingCache

- (NSManagedObject *)findInstanceOfEntity:(NSEntityDescription *)entity
                              withMapping:(RKManagedObjectMapping *)mapping
                       andPrimaryKeyValue:(id)primaryKeyValue
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSAssert(entity, @"Cannot find existing managed object without a target class");
    NSAssert(mapping, @"Cannot find existing managed object instance without mapping");
    NSAssert(mapping.primaryKeyAttribute, @"Cannot find existing managed object instance without mapping that defines a primaryKeyAttribute");
    NSAssert(primaryKeyValue, @"Cannot find existing managed object by primary key without a value");
    NSAssert(managedObjectContext, @"Cannot find existing managed object with a context");

    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchLimit:1];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", mapping.primaryKeyAttribute, primaryKeyValue]];
    NSArray *objects = [NSManagedObject executeFetchRequest:fetchRequest];
    RKLogDebug(@"Found objects '%@' using fetchRequest '%@'", objects, fetchRequest);

    NSManagedObject *object = nil;
    if ([objects count] > 0) {
        object = [objects objectAtIndex:0];
    }
    return object;
}

@end
