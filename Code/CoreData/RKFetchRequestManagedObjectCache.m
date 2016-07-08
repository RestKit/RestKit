//
//  RKFetchRequestManagedObjectCache.m
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
    NSArray *sortedKeys = [[attributesValues allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *keyFragments = [NSMutableArray array];
    for (NSString *attributeName in sortedKeys) {
        id value = attributesValues[attributeName];
        NSString *suffix = [value respondsToSelector:@selector(count)] ? @"+" : @".";
        [keyFragments addObject:[attributeName stringByAppendingString:suffix]];
    }
    return [keyFragments componentsJoinedByString:@":"];
}

// NOTE: We make sure to convert the attribute values to compatible names that can be replaced correctly by `predicateWithSubstitutionVariables`
static NSString *RKAttributePlaceholderForAttributeName(NSString *attributeName)
{
    return [[attributeName componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] componentsJoinedByString:@"_"];
}

static NSDictionary *RKSubstitutionVariablesForAttributeValues(NSDictionary *attributeValues)
{
    NSMutableDictionary *placeholders = [[NSMutableDictionary alloc] initWithCapacity:attributeValues.count];
    [attributeValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        placeholders[RKAttributePlaceholderForAttributeName(key)] = value;
    }];

    return [NSDictionary dictionaryWithDictionary:placeholders];
}

// NOTE: We build a dynamic format string here because `NSCompoundPredicate` does not support use of substitution variables
static NSPredicate *RKPredicateWithSubstitutionVariablesForAttributeValues(NSDictionary *attributeValues)
{
    NSArray *attributeNames = [attributeValues allKeys];
    NSMutableArray *formatFragments = [NSMutableArray arrayWithCapacity:[attributeNames count]];
    [attributeValues enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, id value, BOOL *stop) {
        NSString *formatFragment = RKObjectIsCollection(value)
                                 ? [NSString stringWithFormat:@"%@ IN $%@", attributeName, RKAttributePlaceholderForAttributeName(attributeName)]
                                 : [NSString stringWithFormat:@"%@ = $%@", attributeName, RKAttributePlaceholderForAttributeName(attributeName)];
        [formatFragments addObject:formatFragment];
    }];

    return [NSPredicate predicateWithFormat:[formatFragments componentsJoinedByString:@" AND "]];
}

@interface RKFetchRequestManagedObjectCache ()
@property (nonatomic, strong) NSMutableDictionary *predicateCache;
#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t cacheQueue;
#else
@property (nonatomic, assign) dispatch_queue_t cacheQueue;
#endif
@end

@implementation RKFetchRequestManagedObjectCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.predicateCache = [NSMutableDictionary dictionary];
        self.cacheQueue = dispatch_queue_create("org.restkit.core-data.fetch-request-cache-queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)dealloc
{
#if !OS_OBJECT_USE_OBJC
    if (_cacheQueue) dispatch_release(_cacheQueue);
#endif
    _cacheQueue = NULL;
}

- (NSSet *)managedObjectsWithEntity:(NSEntityDescription *)entity
                    attributeValues:(NSDictionary *)attributeValues
             inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSAssert(entity, @"Cannot find existing managed object without a target class");
    NSAssert(attributeValues, @"Cannot retrieve cached objects without attribute values to identify them with.");
    NSAssert(managedObjectContext, @"Cannot find existing managed object with a nil context");
    
    if ([attributeValues count] == 0) return [NSSet set];
    
    NSString *predicateCacheKey = RKPredicateCacheKeyForAttributeValues(attributeValues);
    
    __block NSPredicate *substitutionPredicate;
    dispatch_sync(self.cacheQueue, ^{
        substitutionPredicate = (self.predicateCache)[predicateCacheKey];
    });
    
    NSDictionary *substitutionVariables = RKSubstitutionVariablesForAttributeValues(attributeValues);
    
    if (! substitutionPredicate) {
        substitutionPredicate = RKPredicateWithSubstitutionVariablesForAttributeValues(attributeValues);
        dispatch_barrier_async(self.cacheQueue, ^{
            (self.predicateCache)[predicateCacheKey] = substitutionPredicate;
        });
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[entity name]];
    fetchRequest.predicate = [substitutionPredicate predicateWithSubstitutionVariables:substitutionVariables];
    __block NSError *error = nil;
    __block NSArray *objects = nil;
    [managedObjectContext performBlockAndWait:^{
        objects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    if (! objects) {
        RKLogError(@"Failed to execute fetch request due to error: %@", error);
    }
    RKLogDebug(@"Found objects '%@' using fetchRequest '%@'", objects, fetchRequest);

    return [NSSet setWithArray:objects];
}

@end
