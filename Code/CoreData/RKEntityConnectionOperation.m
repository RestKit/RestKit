//
//  RKEntityConnectionOperation.m
//  RestKit
//
//  Created by Blake Watters on 7/4/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKEntityConnectionOperation.h"
#import "RKEntityMapping.h"
#import "RKDynamicObjectMappingMatcher.h"
#import "RKManagedObjectStore.h"
#import "RKLog.h"
#import "RKConnectionMapping.h"
#import "RKManagedObjectCaching.h"
#import "RKRelationshipConnectionOperation.h"

@interface RKEntityConnectionOperation ()
@property (nonatomic, retain) NSManagedObjectID *managedObjectID;
@property (nonatomic, retain) NSManagedObjectContext *parentManagedObjectContext;
@property (nonatomic, retain) NSManagedObjectContext *childManagedObjectContext;
@property (nonatomic, retain) NSManagedObject *childManagedObject;
@property (nonatomic, retain) RKEntityMapping *entityMapping;
@property (nonatomic, retain) id<RKManagedObjectCaching> managedObjectCache;
@end

@implementation RKEntityConnectionOperation

@synthesize managedObjectID = _managedObjectID;
@synthesize parentManagedObjectContext = _parentManagedObjectContext;
@synthesize childManagedObjectContext = _childManagedObjectContext;
@synthesize childManagedObject = _childManagedObject;
@synthesize entityMapping = _entityMapping;
@synthesize managedObjectCache = _managedObjectCache;

- (id)initWithManagedObject:(NSManagedObject *)managedObject entityMapping:(RKEntityMapping *)entityMapping managedObjectCache:(id<RKManagedObjectCaching>)managedObjectCache
{
    self = [super init];
    if (self) {
        self.managedObjectID = [managedObject objectID];
        self.parentManagedObjectContext = [managedObject managedObjectContext];
        self.entityMapping = entityMapping;
    }
    
    return self;
}

- (void)dealloc
{
    self.managedObjectID = nil;
    self.parentManagedObjectContext = nil;
    self.childManagedObjectContext = nil;
    self.entityMapping = nil;
    self.managedObjectCache = nil;
    
    [super dealloc];
}

//- (void)addDependenciesForConnectionMappings
//{
//    RKLogTrace(@"Connecting relationships for managed object %@ using connection mappings: %@", self.managedObject, self.entityMapping.connections);
//    for (RKConnectionMapping *connectionMapping in self.entityMapping.connections) {
//        RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:self.managedObject connectionMapping:connectionMapping managedObjectCache:self.managedObjectCache];
//        [self addDependency:operation];
//        NSLog(@"Adding dependencies to queue: %@", [NSOperationQueue currentQueue]);
//        [[NSOperationQueue currentQueue] addOperation:operation];
//        [operation release];
//    }
//    
//    NSLog(@"Added dependencies: %@", self.dependencies);
//}

- (NSManagedObject *)findOneConnectedWithSourceValue:(id)sourceValue connectionMapping:(RKConnectionMapping *)connectionMapping
{
    return [self.managedObjectCache findInstanceOfEntity:self.entityMapping.entity
                                 withPrimaryKeyAttribute:connectionMapping.destinationKeyPath
                                                   value:sourceValue
                                  inManagedObjectContext:self.childManagedObjectContext];
}

- (NSMutableSet *)findAllConnectedWithSourceValue:(id)sourceValue connectionMapping:(RKConnectionMapping *)connectionMapping
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
                                                  withPrimaryKeyAttribute:connectionMapping.destinationKeyPath
                                                                    value:value
                                                   inManagedObjectContext:self.childManagedObjectContext];
        [result addObjectsFromArray:objects];
    }
    return result;
}

- (BOOL)isToManyWithConnectionMapping:(RKConnectionMapping *)connectionMapping
{
    NSEntityDescription *entity = [self.childManagedObject entity];
    NSDictionary *relationships = [entity relationshipsByName];
    NSRelationshipDescription *relationship = [relationships objectForKey:connectionMapping.relationshipName];
    return relationship.isToMany;
}

- (BOOL)checkMatcherWithConnectionMapping:(RKConnectionMapping *)connectionMapping
{
    if (!connectionMapping.matcher) {
        return YES;
    } else {
        return [connectionMapping.matcher isMatchForData:self.childManagedObject];
    }
}

- (id)findConnectedWithConnectionMapping:(RKConnectionMapping *)connectionMapping
{
    if ([self checkMatcherWithConnectionMapping:connectionMapping]) {
        BOOL isToMany = [self isToManyWithConnectionMapping:connectionMapping];
        NSLog(@"Attempting to get valueForKey %@ from childManagedObject: %@", connectionMapping.sourceKeyPath, self.childManagedObject);
        id sourceValue = [self.childManagedObject valueForKey:connectionMapping.sourceKeyPath];
        if (isToMany) {
            return [self findAllConnectedWithSourceValue:sourceValue connectionMapping:connectionMapping];
        } else {
            return [self findOneConnectedWithSourceValue:sourceValue connectionMapping:connectionMapping];
        }
    } else {
        return nil;
    }
}

- (void)connectRelationshipWithConnectionMapping:(RKConnectionMapping *)connectionMapping
{
    RKLogTrace(@"Connecting relationship '%@'", connectionMapping.relationshipName);
    
    id relatedObject = [self findConnectedWithConnectionMapping:connectionMapping];
    if (relatedObject) {
        [self.childManagedObject setValue:relatedObject forKeyPath:connectionMapping.relationshipName];
        RKLogDebug(@"Connected relationship '%@' to object '%@'", connectionMapping.relationshipName, relatedObject);
    } else {
        RKEntityMapping *entityMapping = (RKEntityMapping *)connectionMapping.mapping;
        RKLogDebug(@"Failed to find instance of '%@' to connect relationship '%@'", [[entityMapping entity] name], connectionMapping.relationshipName);
    }
}

- (void)connectRelationships
{
    RKLogTrace(@"Connecting relationships for managed object %@ using connection mappings: %@", self.childManagedObject, self.entityMapping.connections);
    for (RKConnectionMapping *connectionMapping in self.entityMapping.connections) {
        [self connectRelationshipWithConnectionMapping:connectionMapping];
    }
}

- (void)performConnections
{
    self.childManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];    
//    [self.childManagedObjectContext release];
    
    NSLog(@"The parent managed object context = %@. Concurrency Type = %d", self.parentManagedObjectContext, self.parentManagedObjectContext.concurrencyType);
    NSLog(@"The child managed object context = %@. Concurrency Type = %d", self.childManagedObjectContext, self.childManagedObjectContext.concurrencyType);
    
    __block BOOL success;
    __block NSError *error;
    [self.childManagedObjectContext performBlockAndWait:^{
        self.childManagedObjectContext.parentContext = self.parentManagedObjectContext;
        
        // Sanity checking...
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
        [fetchRequest setIncludesSubentities:YES];
        //        [fetchRequest setIncludesPendingChanges:YES];
        NSLog(@"About to execute a fetch...");
//        NSArray *objects = [self.parentManagedObjectContext executeFetchRequest:fetchRequest error:&error];
//        NSLog(@"The following objects are in the parent store: %@", objects);
        NSArray *objects = [self.childManagedObjectContext executeFetchRequest:fetchRequest error:&error];
        NSLog(@"The following objects are in the child store: %@", objects);
        if (! objects) {
        }
        
        //        self.childManagedObject = [self.childManagedObjectContext objectWithID:self.managedObjectID];
        NSLog(@"What the fuck???");
//        NSLog(@"The child object's railsID is: ", [self.childManagedObject valueForKey:@"railsID"]);
        
        [self connectRelationships];
        
        if ([self.childManagedObjectContext hasChanges]) {
            RKLogInfo(@"Connection of relationships was successful, saving child managed object context...");
            success = [self.childManagedObjectContext save:&error];
            if (success) {
                success = [self.parentManagedObjectContext save:&error];
                if (! success) {
                    RKLogError(@"Failed to save connection changes to parent managed object context: %@", [error localizedDescription]);
                }
            } else {
                RKLogError(@"Saving of child managed object context failed: %@", [error localizedDescription]);
            }
        }
    }];
}

- (void)main
{
    @try {
        [self performConnections];
    }
    @catch (NSException *exception) {
        NSLog(@"Got an exception!!!!");
    }
}

@end
