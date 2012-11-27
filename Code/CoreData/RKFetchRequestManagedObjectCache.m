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

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

static NSString *RKPredicateCacheKeyForAttributes(NSArray *attributeNames)
{
    return [[attributeNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] componentsJoinedByString:@":"];
}

// NOTE: We build a dynamic format string here because `NSCompoundPredicate` does not support use of substiution variables
static NSPredicate *RKPredicateWithSubsitutionVariablesForAttributes(NSArray *attributeNames)
{
    NSMutableArray *formatFragments = [NSMutableArray arrayWithCapacity:[attributeNames count]];
    for (NSString *attributeName in attributeNames) {
        NSString *formatFragment = [NSString stringWithFormat:@"%@ = $%@", attributeName, attributeName];
        [formatFragments addObject:formatFragment];
    }

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

- (NSArray *)managedObjectsWithEntity:(NSEntityDescription *)entity
                      attributeValues:(NSDictionary *)attributeValues
               inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{

    NSAssert(entity, @"Cannot find existing managed object without a target class");
    NSAssert(attributeValues, @"Cannot retrieve cached objects without attribute values to identify them with.");
    NSAssert(managedObjectContext, @"Cannot find existing managed object with a nil context");
    
    NSString *predicateCacheKey = RKPredicateCacheKeyForAttributes([attributeValues allKeys]);
    NSPredicate *substitutionPredicate = [self.predicateCache objectForKey:predicateCacheKey];
    if (! substitutionPredicate) {
        substitutionPredicate = RKPredicateWithSubsitutionVariablesForAttributes([attributeValues allKeys]);
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

    return objects;
}

@end
