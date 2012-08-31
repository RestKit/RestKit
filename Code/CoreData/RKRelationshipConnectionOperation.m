//
//  RKRelationshipConnectionOperation.m
//  RestKit
//
//  Created by Blake Watters on 7/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKRelationshipConnectionOperation.h"
#import "RKEntityMapping.h"
#import "RKLog.h"
#import "RKManagedObjectCaching.h"
#import "RKDynamicMappingMatcher.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@interface RKRelationshipConnectionOperation ()
@property (nonatomic, strong, readwrite) NSManagedObject *managedObject;
@property (nonatomic, strong, readwrite) RKConnectionMapping *connectionMapping;
@property (nonatomic, strong, readwrite) id<RKManagedObjectCaching> managedObjectCache;

// Helpers
@property (weak, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@end

@implementation RKRelationshipConnectionOperation

@synthesize managedObject = _managedObject;
@synthesize connectionMapping = _connectionMapping;
@synthesize managedObjectCache = _managedObjectCache;

- (id)initWithManagedObject:(NSManagedObject *)managedObject connectionMapping:(RKConnectionMapping *)connectionMapping managedObjectCache:(id<RKManagedObjectCaching>)managedObjectCache
{
    self = [self init];
    if (self) {
        self.managedObject = managedObject;
        self.connectionMapping = connectionMapping;
        self.managedObjectCache = managedObjectCache;
    }
    
    return self;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.managedObject.managedObjectContext;
}

- (NSManagedObject *)findOneConnectedWithSourceValue:(id)sourceValue
{
    return [self.managedObjectCache findInstanceOfEntity:self.connectionMapping.relationship.destinationEntity
                                 withPrimaryKeyAttribute:self.connectionMapping.destinationKeyPath
                                                   value:sourceValue
                                  inManagedObjectContext:self.managedObjectContext];
}

- (id)relationshipValueWithConnectionResult:(id)result
{
    // TODO: Replace with use of object mapping engine for type conversion

    // NOTE: This is a nasty hack to work around the fact that NSOrderedSet does not support key-value
    // collection operators. We try to detect and unpack a doubly wrapped collection
    if ([self.connectionMapping.relationship isOrdered]
        && [result conformsToProtocol:@protocol(NSFastEnumeration)]
        && [[result lastObject] conformsToProtocol:@protocol(NSFastEnumeration)]) {

        NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
        for (id<NSFastEnumeration> enumerable in result) {
            for (id object in enumerable) {
                [set addObject:object];
            }
        }

        return set;
    }

    if ([self.connectionMapping.relationship isToMany]) {
        if ([result isKindOfClass:[NSArray class]]) {
            if ([self.connectionMapping.relationship isOrdered]) {
                return [NSOrderedSet orderedSetWithArray:result];
            } else {
                return [NSSet setWithArray:result];
            }
        } else if ([result isKindOfClass:[NSSet class]]) {
            if ([self.connectionMapping.relationship isOrdered]) {
                return [NSOrderedSet orderedSetWithSet:result];
            } else {
                return result;
            }
        } else {
            if ([self.connectionMapping.relationship isOrdered]) {
                return [NSOrderedSet orderedSetWithObject:result];
            } else {
                return [NSSet setWithObject:result];
            }
        }
    }

    return result;
}

- (NSMutableSet *)findAllConnectedWithSourceValue:(id)sourceValue
{
    NSMutableSet *result = [NSMutableSet set];
    
    id values = nil;
    if ([sourceValue conformsToProtocol:@protocol(NSFastEnumeration)]) {
        values = sourceValue;
    } else {
        values = [NSArray arrayWithObject:sourceValue];
    }
    
    for (id value in values) {
        NSArray *objects = [self.managedObjectCache findInstancesOfEntity:self.connectionMapping.relationship.destinationEntity
                                                  withPrimaryKeyAttribute:self.connectionMapping.destinationKeyPath
                                                                    value:value
                                                   inManagedObjectContext:self.managedObjectContext];
        [result addObjectsFromArray:objects];
    }
    return result;
}

- (BOOL)isToMany
{
    return self.connectionMapping.relationship.isToMany;
}

- (BOOL)checkMatcher
{
    if (!self.connectionMapping.matcher) {
        return YES;
    } else {
        return [self.connectionMapping.matcher isMatchForData:self.managedObject];
    }
}

- (id)findConnected
{
    if ([self checkMatcher]) {
        id connectionResult = nil;
        if ([self.connectionMapping isForeignKeyConnection]) {
            BOOL isToMany = [self isToMany];
            id sourceValue = [self.managedObject valueForKey:self.connectionMapping.sourceKeyPath];
            if (isToMany) {
                connectionResult = [self findAllConnectedWithSourceValue:sourceValue];
            } else {
                connectionResult = [self findOneConnectedWithSourceValue:sourceValue];
            }
        } else if ([self.connectionMapping isKeyPathConnection]) {
            connectionResult = [self.managedObject valueForKeyPath:self.connectionMapping.sourceKeyPath];
        } else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:[NSString stringWithFormat:@"%@ Attempted to establish a relationship using a mapping"
                                                   "specifies neither a foreign key or a key path connection: %@",
                                                   NSStringFromClass([self class]), self.connectionMapping]
                                         userInfo:nil];
        }

        return [self relationshipValueWithConnectionResult:connectionResult];
    } else {
        return nil;
    }
}

- (void)connectRelationship
{
    NSString *relationshipName = self.connectionMapping.relationship.name;
    RKLogTrace(@"Connecting relationship '%@' with mapping: %@", relationshipName, self.connectionMapping);
    [self.managedObjectContext performBlockAndWait:^{
        id relatedObject = [self findConnected];
        if (relatedObject) {
            [self.managedObject setValue:relatedObject forKeyPath:relationshipName];
            RKLogDebug(@"Connected relationship '%@' to object '%@'", relationshipName, relatedObject);
        } else {
            RKLogDebug(@"Failed to find instance of '%@' to connect relationship '%@'", [[self.connectionMapping.relationship destinationEntity] name], relationshipName);
        }
    }];
}

- (void)main
{
    if (self.isCancelled) return;
    @try {
        [self connectRelationship];
    }
    @catch (NSException *exception) {
        RKLogCritical(@"Caught exception: %@", exception);
    }
}

@end
