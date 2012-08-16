//
//  RKEntityByAttributeCache.m
//  RestKit
//
//  Created by Blake Watters on 5/1/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "RKEntityByAttributeCache.h"
#import "RKLog.h"
#import "RKPropertyInspector.h"
#import "RKPropertyInspector+CoreData.h"
#import "NSManagedObject+RKAdditions.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreDataCache

@interface RKEntityByAttributeCache ()
@property (nonatomic, retain) NSMutableDictionary *attributeValuesToObjectIDs;
@end

@implementation RKEntityByAttributeCache

@synthesize entity = _entity;
@synthesize attribute = _attribute;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize attributeValuesToObjectIDs = _attributeValuesToObjectIDs;
@synthesize monitorsContextForChanges = _monitorsContextForChanges;

- (id)initWithEntity:(NSEntityDescription *)entity attribute:(NSString *)attributeName managedObjectContext:(NSManagedObjectContext *)context
{
    self = [self init];
    if (self) {
        _entity = [entity retain];
        _attribute = [attributeName retain];
        _managedObjectContext = [context retain];
        _monitorsContextForChanges = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:context];
        
#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
#endif
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_entity release];
    [_attribute release];
    [_managedObjectContext release];
    [_attributeValuesToObjectIDs release];

    [super dealloc];
}

- (NSUInteger)count
{
    return [[[self.attributeValuesToObjectIDs allValues] valueForKeyPath:@"@sum.@count"] integerValue];
}

- (NSUInteger)countOfAttributeValues
{
    return [self.attributeValuesToObjectIDs count];
}

- (NSUInteger)countWithAttributeValue:(id)attributeValue
{
    return [[self objectsWithAttributeValue:attributeValue inContext:self.managedObjectContext] count];
}

- (BOOL)shouldCoerceAttributeToString:(NSString *)attributeValue
{
    if ([attributeValue isKindOfClass:[NSString class]] || [attributeValue isEqual:[NSNull null]]) {
        return NO;
    }

    Class attributeType = [[RKPropertyInspector sharedInspector] typeForProperty:self.attribute ofEntity:self.entity];
    return [attributeType instancesRespondToSelector:@selector(stringValue)];
}

- (void)load
{
    RKLogDebug(@"Loading entity cache for Entity '%@' by attribute '%@' in managed object context %@ (concurrencyType = %ld)",
               self.entity.name, self.attribute, self.managedObjectContext, (unsigned long) self.managedObjectContext.concurrencyType);
    @synchronized(self.attributeValuesToObjectIDs) {
        self.attributeValuesToObjectIDs = [NSMutableDictionary dictionary];

        NSExpressionDescription* objectIDExpression = [[NSExpressionDescription new] autorelease];
        objectIDExpression.name = @"objectID";
        objectIDExpression.expression = [NSExpression expressionForEvaluatedObject];
        objectIDExpression.expressionResultType = NSObjectIDAttributeType;

        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = self.entity;
        fetchRequest.resultType = NSDictionaryResultType;
        fetchRequest.propertiesToFetch = [NSArray arrayWithObjects:objectIDExpression, self.attribute, nil];
        [self.managedObjectContext performBlockAndWait:^{
            NSError *error;
            NSArray *dictionaries = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
            if (!dictionaries) {
                RKLogWarning(@"Failed to load entity cache. Failed to execute fetch request: %@", fetchRequest);
                RKLogCoreDataError(error);
            }

            for (NSDictionary *dictionary in dictionaries) {
                id attributeValue = [dictionary objectForKey:self.attribute];
                NSManagedObjectID *objectID = [dictionary objectForKey:@"objectID"];
                [self setObjectID:objectID forAttributeValue:attributeValue];
            }
         }];
    }
}

- (void)flush
{
    @synchronized(self.attributeValuesToObjectIDs) {
        RKLogDebug(@"Flushing entity cache for Entity '%@' by attribute '%@'", self.entity.name, self.attribute);
        self.attributeValuesToObjectIDs = nil;
    }
}

- (void)reload
{
    [self flush];
    [self load];
}

- (BOOL)isLoaded
{
    return (self.attributeValuesToObjectIDs != nil);
}

- (NSManagedObject *)objectForObjectID:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)context
{
    /*
     NOTE:
     We use existingObjectWithID: as opposed to objectWithID: as objectWithID: can return us a fault
     that will raise an exception when fired. existingObjectWithID:error: will return nil if the ID has been
     deleted. objectRegisteredForID: is also an acceptable approach.
     */
    NSError *error = nil;
    NSManagedObject *object;
    object = [context existingObjectWithID:objectID error:&error];
    if (! object) {
        if (error) {
            RKLogError(@"Failed to retrieve managed object with ID %@. Error %@\n%@", objectID, [error localizedDescription], [error userInfo]);
        }
        
        return nil;
    }
    
    return object;
}

- (NSManagedObject *)objectWithAttributeValue:(id)attributeValue inContext:(NSManagedObjectContext *)context
{
    NSArray *objects = [self objectsWithAttributeValue:attributeValue inContext:context];
    return ([objects count] > 0) ? [objects objectAtIndex:0] : nil;
}

- (NSArray *)objectsWithAttributeValue:(id)attributeValue inContext:(NSManagedObjectContext *)context
{
    attributeValue = [self shouldCoerceAttributeToString:attributeValue] ? [attributeValue stringValue] : attributeValue;
    NSMutableArray *objectIDs = [[self.attributeValuesToObjectIDs objectForKey:attributeValue] copy];
    if (objectIDs) {
        /**
         NOTE:
         In my benchmarking, retrieving the objects one at a time using existingObjectWithID: is significantly faster
         than issuing a single fetch request against all object ID's.
         */
        NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[objectIDs count]];
        for (NSManagedObjectID *objectID in objectIDs) {
            NSManagedObject *object = [self objectForObjectID:objectID inContext:context];
            if (object) {
                [objects addObject:object];
            } else {
                RKLogDebug(@"Evicting objectID association for attribute '%@'=>'%@' of Entity '%@': %@", self.attribute, attributeValue, self.entity.name, objectID);
                [self removeObjectID:objectID forAttributeValue:attributeValue];
            }
        }

        return objects;
    }

    return [NSArray array];
}

- (void)setObjectID:(NSManagedObjectID *)objectID forAttributeValue:(id)attributeValue
{
    @synchronized(self.attributeValuesToObjectIDs) {
        attributeValue = [self shouldCoerceAttributeToString:attributeValue] ? [attributeValue stringValue] : attributeValue;
        if (attributeValue) {
            NSMutableArray *objectIDs = [self.attributeValuesToObjectIDs objectForKey:attributeValue];
            if (objectIDs) {
                if (! [objectIDs containsObject:objectID]) {
                    [objectIDs addObject:objectID];
                }
            } else {
                objectIDs = [NSMutableArray arrayWithObject:objectID];
            }


            if (nil == self.attributeValuesToObjectIDs) self.attributeValuesToObjectIDs = [NSMutableDictionary dictionary];
            [self.attributeValuesToObjectIDs setValue:objectIDs forKey:attributeValue];
        } else {
            RKLogWarning(@"Unable to add object for object ID %@: nil value for attribute '%@'", objectID, self.attribute);
        }
    }
}

- (void)removeObjectID:(NSManagedObjectID *)objectID forAttributeValue:(id)attributeValue
{
    @synchronized(self.attributeValuesToObjectIDs) {
        // Coerce to a string if possible
        attributeValue = [self shouldCoerceAttributeToString:attributeValue] ? [attributeValue stringValue] : attributeValue;
        if (attributeValue) {
            NSMutableArray *objectIDs = [self.attributeValuesToObjectIDs objectForKey:attributeValue];
            if (objectIDs && [objectIDs containsObject:objectID]) {
                [objectIDs removeObject:objectID];
            }
        } else {
            RKLogWarning(@"Unable to remove object for object ID %@: nil value for attribute '%@'", objectID, self.attribute);
        }
    }
}

- (void)addObject:(NSManagedObject *)object
{
    __block NSEntityDescription *entity;
    __block id attributeValue;
    __block NSManagedObjectID *objectID;
    [self.managedObjectContext performBlockAndWait:^{
        entity = object.entity;
        objectID = [object objectID];
        attributeValue = [object valueForKey:self.attribute];
    }];
    NSAssert([entity isEqual:self.entity], @"Cannot add object with entity '%@' to cache for entity of '%@'", [entity name], [self.entity name]);
    // Coerce to a string if possible
    [self setObjectID:objectID forAttributeValue:attributeValue];
}

- (void)removeObject:(NSManagedObject *)object
{
    __block NSEntityDescription *entity;
    __block id attributeValue;
    __block NSManagedObjectID *objectID;
    [object.managedObjectContext performBlockAndWait:^{
        entity = object.entity;
        objectID = [object objectID];
        attributeValue = [object valueForKey:self.attribute];
    }];
    NSAssert([entity isEqual:self.entity], @"Cannot remove object with entity '%@' from cache for entity of '%@'", [entity name], [self.entity name]);
    [self removeObjectID:objectID forAttributeValue:attributeValue];
}

- (BOOL)containsObjectWithAttributeValue:(id)attributeValue
{
    // Coerce to a string if possible
    attributeValue = [self shouldCoerceAttributeToString:attributeValue] ? [attributeValue stringValue] : attributeValue;
    return [[self objectsWithAttributeValue:attributeValue inContext:self.managedObjectContext] count] > 0;
}

- (BOOL)containsObject:(NSManagedObject *)object
{
    NSArray *allObjectIDs = [[self.attributeValuesToObjectIDs allValues] valueForKeyPath:@"@distinctUnionOfArrays.self"];
    return [allObjectIDs containsObject:object.objectID];
}

- (void)managedObjectContextDidChange:(NSNotification *)notification
{
    if (self.monitorsContextForChanges == NO) return;

    NSDictionary *userInfo = notification.userInfo;
    NSSet *insertedObjects = [userInfo objectForKey:NSInsertedObjectsKey];
    NSSet *updatedObjects = [userInfo objectForKey:NSUpdatedObjectsKey];
    NSSet *deletedObjects = [userInfo objectForKey:NSDeletedObjectsKey];
    RKLogTrace(@"insertedObjects=%@, updatedObjects=%@, deletedObjects=%@", insertedObjects, updatedObjects, deletedObjects);

    NSMutableSet *objectsToAdd = [NSMutableSet setWithSet:insertedObjects];
    [objectsToAdd unionSet:updatedObjects];

    for (NSManagedObject *object in objectsToAdd) {
        if ([object.entity isEqual:self.entity]) {
            [self addObject:object];
        }
    }

    for (NSManagedObject *object in deletedObjects) {
        if ([object.entity isEqual:self.entity]) {
            [self removeObject:object];
        }
    }
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    [self flush];
}

@end
