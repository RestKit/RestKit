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

@interface RKRelationshipConnectionOperation ()
@property (nonatomic, retain, readwrite) NSManagedObject *managedObject;
@property (nonatomic, retain, readwrite) RKConnectionMapping *connectionMapping;
@property (nonatomic, retain, readwrite) id<RKManagedObjectCaching> managedObjectCache;

// Helpers
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) RKEntityMapping *entityMapping;

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

- (void)dealloc
{
    self.managedObject = nil;
    self.connectionMapping = nil;
    self.managedObjectCache = nil;

    [super dealloc];
}

- (RKEntityMapping *)entityMapping
{
    return (RKEntityMapping *)self.connectionMapping.mapping;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.managedObject.managedObjectContext;
}

- (NSManagedObject *)findOneConnectedWithSourceValue:(id)sourceValue
{
    return [self.managedObjectCache findInstanceOfEntity:self.entityMapping.entity
                                 withPrimaryKeyAttribute:self.connectionMapping.destinationKeyPath
                                                   value:sourceValue
                                  inManagedObjectContext:self.managedObjectContext];
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
        NSArray *objects = [self.managedObjectCache findInstancesOfEntity:self.entityMapping.entity
                                                  withPrimaryKeyAttribute:self.connectionMapping.destinationKeyPath
                                                                    value:value
                                                   inManagedObjectContext:self.managedObjectContext];
        [result addObjectsFromArray:objects];
    }
    return result;
}

- (BOOL)isToMany
{
    NSEntityDescription *entity = [self.managedObject entity];
    NSDictionary *relationships = [entity relationshipsByName];
    NSRelationshipDescription *relationship = [relationships objectForKey:self.connectionMapping.relationshipName];
    return relationship.isToMany;
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
        BOOL isToMany = [self isToMany];
        id sourceValue = [self.managedObject valueForKey:self.connectionMapping.sourceKeyPath];
        if (isToMany) {
            return [self findAllConnectedWithSourceValue:sourceValue];
        } else {
            return [self findOneConnectedWithSourceValue:sourceValue];
        }
    } else {
        return nil;
    }
}

- (void)connectRelationship
{
    RKLogTrace(@"Connecting relationship '%@'", self.connectionMapping.relationshipName);
    
    [self.managedObjectContext performBlockAndWait:^{
        id relatedObject = [self findConnected];
        if (relatedObject) {
            [self.managedObject setValue:relatedObject forKeyPath:self.connectionMapping.relationshipName];
            RKLogDebug(@"Connected relationship '%@' to object '%@'", self.connectionMapping.relationshipName, relatedObject);
        } else {
            RKEntityMapping *objectMapping = (RKEntityMapping *)self.connectionMapping.mapping;
            RKLogDebug(@"Failed to find instance of '%@' to connect relationship '%@'", [[objectMapping entity] name], self.connectionMapping.relationshipName);
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
