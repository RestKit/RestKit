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
 This function computes a cache key given a dictionary of attribute values. Each attribute name is used as a fragment within the aggregate cache key. A suffix qualifier is appended that differentiates singular vs. collection attribute values so that '==' and 'IN' predicates are computed appropriately.
 */
static NSString *RKPredicateCacheKeyForAttributeValues(NSDictionary *attributesValues)
{
    NSArray *sortedKeys = [[attributesValues allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSMutableArray *keyFragments = [NSMutableArray array];
    for (NSString *attributeName in sortedKeys) {
        id value = [attributesValues objectForKey:attributeName];
        char suffix = ([value respondsToSelector:@selector(count)]) ? '+' : '.';
        NSString *attributeKey = [NSString stringWithFormat:@"%@%c", attributeName, suffix];
        [keyFragments addObject:attributeKey];
    }
    return [keyFragments componentsJoinedByString:@":"];
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
    
    NSString *predicateCacheKey = RKPredicateCacheKeyForAttributeValues(attributeValues);
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
