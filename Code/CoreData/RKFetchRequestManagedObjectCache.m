//
//  RKFetchRequestMappingCache.m
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKFetchRequestManagedObjectCache.h"
#import "RKLog.h"
#import "RKPropertyInspector.h"
#import "RKPropertyInspector+CoreData.h"
#import "RKObjectUtilities.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

/*
 NOTE: At the moment this cache key assume that the structure of the values for each key in the `attributeValues` in constant
 i.e. if you have `userID`, it will always be a single value, or `userIDs` will always be an array.
 It will need to be reimplemented if changes in attribute values occur during the life of a single cache
 */
static NSString *RKPredicateCacheKeyForAttributes(NSArray *attributeNames)
{
    return [[attributeNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] componentsJoinedByString:@":"];
}

// NOTE: We build a dynamic format string here because `NSCompoundPredicate` does not support use of substiution variables
static NSPredicate *RKPredicateWithSubsitutionVariablesForAttributeValues(NSDictionary *attributeValues)
{
    NSArray *attributeNames = [attributeValues allKeys];
    NSMutableArray *formatFragments = [NSMutableArray arrayWithCapacity:[attributeNames count]];
    [attributeValues enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, id value, BOOL *stop) {
        NSString *formatFragment = RKObjectIsCollection(value)
                                 ? [NSString stringWithFormat:@"%@ IN $%@", attributeName, attributeName]
                                 : [NSString stringWithFormat:@"%@ = $%@", attributeName, attributeName];
        [formatFragments addObject:formatFragment];
    }];

    return [NSPredicate predicateWithFormat:[formatFragments componentsJoinedByString:@" AND "]];
}

@interface RKFetchRequestManagedObjectCache ()
@property (nonatomic, strong) NSCache *predicateCache;
@end

@implementation RKFetchRequestManagedObjectCache

- (id)init
{
    self = [super init];
    if (self) {
        self.predicateCache = [NSCache new];
    }
    return self;
}

- (NSSet *)managedObjectsWithEntity:(NSEntityDescription *)entity
                    attributeValues:(NSDictionary *)attributeValues
             inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{

    NSAssert(entity, @"Cannot find existing managed object without a target class");
    NSAssert(attributeValues, @"Cannot retrieve cached objects without attribute values to identify them with.");
    NSAssert(managedObjectContext, @"Cannot find existing managed object with a nil context");
    
    NSString *predicateCacheKey = RKPredicateCacheKeyForAttributes([attributeValues allKeys]);
    NSPredicate *substitutionPredicate = [self.predicateCache objectForKey:predicateCacheKey];
    if (! substitutionPredicate) {
        substitutionPredicate = RKPredicateWithSubsitutionVariablesForAttributeValues(attributeValues);
        [self.predicateCache setObject:substitutionPredicate forKey:predicateCacheKey];
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[entity name]];
    fetchRequest.predicate = [substitutionPredicate predicateWithSubstitutionVariables:attributeValues];
    NSError *error = nil;
    NSArray *objects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (! objects) {
        RKLogError(@"Failed to execute fetch request due to error: %@", error);
    }
    RKLogDebug(@"Found objects '%@' using fetchRequest '%@'", objects, fetchRequest);

    return [NSSet setWithArray:objects];
}

@end
