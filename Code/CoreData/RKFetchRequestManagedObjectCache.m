//
//  RKFetchRequestMappingCache.m
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKFetchRequestManagedObjectCache.h"
#import "NSManagedObject+ActiveRecord.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKLog.h"
#import "RKObjectPropertyInspector.h"
#import "RKObjectPropertyInspector+CoreData.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@implementation RKFetchRequestManagedObjectCache

- (NSManagedObject *)findInstanceOfEntity:(NSEntityDescription *)entity 
                      withPrimaryKeyValue:(id)primaryKeyValue inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSAssert(entity, @"Cannot find existing managed object without a target class");
    NSAssert(primaryKeyValue, @"Cannot find existing managed object by primary key without a value");
    NSAssert(managedObjectContext, @"Cannot find existing managed object with a context");
    
    id searchValue = primaryKeyValue;
    Class type = [[RKObjectPropertyInspector sharedInspector] typeForProperty:entity.primaryKeyAttribute ofEntity:entity];
    if (type && ([type isSubclassOfClass:[NSString class]] && NO == [primaryKeyValue isKindOfClass:[NSString class]])) {
        searchValue = [NSString stringWithFormat:@"%@", primaryKeyValue];
    } else if (type && ([type isSubclassOfClass:[NSNumber class]] && NO == [primaryKeyValue isKindOfClass:[NSNumber class]])) {
        if ([primaryKeyValue isKindOfClass:[NSString class]]) {
            searchValue = [NSNumber numberWithDouble:[(NSString *)primaryKeyValue doubleValue]];
        }
    }
    
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:searchValue];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = entity;
    fetchRequest.fetchLimit = 1;
    fetchRequest.predicate = predicate;
    NSArray *objects = [NSManagedObject executeFetchRequest:fetchRequest inContext:managedObjectContext];
    RKLogDebug(@"Found objects '%@' using fetchRequest '%@'", objects, fetchRequest);
    [fetchRequest release];
    
    NSManagedObject *object = nil;
    if ([objects count] > 0) {
        object = [objects objectAtIndex:0];
    }
    return object;
}

@end
