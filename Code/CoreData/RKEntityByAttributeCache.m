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
#import "RKObjectPropertyInspector.h"
#import "RKObjectPropertyInspector+CoreData.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(managedObjectContextDidSave:) 
                                                     name:NSManagedObjectContextDidSaveNotification 
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
    return [self.attributeValuesToObjectIDs count];
}

- (NSUInteger)countWithAttributeValue:(id)attributeValue
{
    return [[self objectsWithAttributeValue:attributeValue] count];
}

- (BOOL)shouldCoerceAttributeToString:(NSString *)attributeValue
{
    if ([attributeValue isKindOfClass:[NSString class]] || [attributeValue isEqual:[NSNull null]]) {
        return NO;
    }
    
    Class attributeType = [[RKObjectPropertyInspector sharedInspector] typeForProperty:self.attribute ofEntity:self.entity];
    return [attributeType instancesRespondToSelector:@selector(stringValue)];
}

- (void)load
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:self.entity];
    [fetchRequest setResultType:NSManagedObjectIDResultType];
    
    NSError *error = nil;
    NSArray *objectIDs = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        RKLogError(@"Failed to load entity cache: %@", error);
        return;
    }
    [fetchRequest release];
    
    self.attributeValuesToObjectIDs = [NSMutableDictionary dictionaryWithCapacity:[objectIDs count]];
    for (NSManagedObjectID* objectID in objectIDs) {
        NSError *error = nil;
        NSManagedObject *object = [self.managedObjectContext existingObjectWithID:objectID error:&error];
        if (! object && error) {
            RKLogError(@"Failed to retrieve managed object with ID %@: %@", objectID, error);
        }
        
        [self addObject:object];
    }
}

- (void)flush
{
    self.attributeValuesToObjectIDs = nil;
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

- (NSManagedObject *)objectWithAttributeValue:(id)attributeValue
{
    return [[self objectsWithAttributeValue:attributeValue] anyObject];
}

- (NSManagedObject *)objectWithID:(NSManagedObjectID *)objectID {
    /*
     NOTE:
     We use existingObjectWithID: as opposed to objectWithID: as objectWithID: can return us a fault
     that will raise an exception when fired. existingObjectWithID:error: will return nil if the ID has been
     deleted. objectRegisteredForID: is also an acceptable approach.
     */
    NSError *error = nil;
    NSManagedObject *object = [self.managedObjectContext existingObjectWithID:objectID error:&error];
    if (! object && error) {
        RKLogError(@"Failed to retrieve managed object with ID %@. Error %@\n%@", objectID, [error localizedDescription], [error userInfo]);
        return nil;
    }
    
    return object;
}

- (NSSet *)objectsWithAttributeValue:(id)attributeValue
{
    attributeValue = [self shouldCoerceAttributeToString:attributeValue] ? [attributeValue stringValue] : attributeValue;
    NSMutableSet *set = [self.attributeValuesToObjectIDs valueForKey:attributeValue];
    if (set) {
        NSSet *objectIDs = [NSSet setWithSet:set];
        NSMutableSet *objects = [NSMutableSet setWithCapacity:[objectIDs count]];
        for (NSManagedObjectID *objectID in objectIDs) {
            NSManagedObject *object = [self objectWithID:objectID];
            if (object) [objects addObject:object];
        }
        
        return objects;
    }
    
    return [NSSet set];
}

- (void)addObject:(NSManagedObject *)object
{
    NSAssert([object.entity isEqual:self.entity], @"Cannot add object with entity '%@' to cache with entity of '%@'", [[object entity] name], [self.entity name]);
    id attributeValue = [object valueForKey:self.attribute];
    // Coerce to a string if possible
    attributeValue = [self shouldCoerceAttributeToString:attributeValue] ? [attributeValue stringValue] : attributeValue;
    if (attributeValue) {
        NSManagedObjectID *objectID = [object objectID];
        BOOL isTemporary = [objectID isTemporaryID];
        NSMutableSet *set = [self.attributeValuesToObjectIDs valueForKey:attributeValue];
        if (set) {
            [set addObject:objectID];
        } else {
            set = [NSMutableSet setWithObject:objectID];
        }
        
        if (nil == self.attributeValuesToObjectIDs) self.attributeValuesToObjectIDs = [NSMutableDictionary dictionary];
        [self.attributeValuesToObjectIDs setValue:set forKey:attributeValue];
    } else {
        RKLogWarning(@"Unable to add object with nil value for attribute '%@': %@", self.attribute, object);
    }
}

- (void)removeObject:(NSManagedObject *)object
{
    NSAssert([object.entity isEqual:self.entity], @"Cannot remove object with entity '%@' from cache with entity of '%@'", [[object entity] name], [self.entity name]);
    id attributeValue = [object valueForKey:self.attribute];
    // Coerce to a string if possible
    attributeValue = [self shouldCoerceAttributeToString:attributeValue] ? [attributeValue stringValue] : attributeValue;
    if (attributeValue) {
        NSManagedObjectID *objectID = [object objectID];
        NSMutableSet *set = [self.attributeValuesToObjectIDs valueForKey:attributeValue];
        if (set) {
            [set removeObject:objectID];
        }
    } else {
        RKLogWarning(@"Unable to remove object with nil value for attribute '%@': %@", self.attribute, object);
    }
}

- (BOOL)containsObjectWithAttributeValue:(id)attributeValue
{
    // Coerce to a string if possible
    attributeValue = [self shouldCoerceAttributeToString:attributeValue] ? [attributeValue stringValue] : attributeValue;
    return [[self objectsWithAttributeValue:attributeValue] count] > 0;
}

- (BOOL)containsObject:(NSManagedObject *)object
{
    if (! [object.entity isEqual:self.entity]) return NO;
    id attributeValue = [object valueForKey:self.attribute];
    // Coerce to a string if possible
    attributeValue = [self shouldCoerceAttributeToString:attributeValue] ? [attributeValue stringValue] : attributeValue;
    return [[self objectsWithAttributeValue:attributeValue] containsObject:object];
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

- (void)managedObjectContextDidSave:(NSNotification *)notification
{
    // After the MOC has been saved, we flush to ensure any temporary
    // objectID references are converted into permanent ID's on the next load.
    [self flush];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    [self flush];
}

@end
