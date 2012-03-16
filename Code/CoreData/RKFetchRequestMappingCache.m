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

    // NOTE: We coerce the primary key into a string (if possible) for convenience. Generally
    // primary keys are expressed either as a number or a string, so this lets us support either case interchangeably
    id lookupValue = [primaryKeyValue respondsToSelector:@selector(stringValue)] ? [primaryKeyValue stringValue] : primaryKeyValue;

    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchLimit:1];
    NSString *predicateString = [mapping.primaryKeyAttribute stringByAppendingString:@" = %@"];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:predicateString, lookupValue]];
    NSArray *objects = [NSManagedObject executeFetchRequest:fetchRequest];
    RKLogDebug(@"Found objects '%@' using fetchRequest '%@'", objects, fetchRequest);

    NSManagedObject *object = nil;
    if ([objects count] > 0) {
        object = [objects objectAtIndex:0];
    }
    return object;
}

@end
