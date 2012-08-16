//
//  RKManagedObjectMappingOperationDataSource.m
//  RestKit
//
//  Created by Blake Watters on 7/3/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKManagedObjectMappingOperationDataSource.h"
#import "RKObjectMapping.h"
#import "RKEntityMapping.h"
#import "RKLog.h"
#import "RKManagedObjectStore.h"
#import "RKMappingOperation.h"
#import "RKDynamicMappingMatcher.h"
#import "RKManagedObjectCaching.h"
#import "RKRelationshipConnectionOperation.h"

@interface RKManagedObjectMappingOperationDataSource ()
@property (nonatomic, retain, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readwrite) id<RKManagedObjectCaching> managedObjectCache;
@property (nonatomic, retain) NSMutableArray *mutableInsertedObjects;
@end

@implementation RKManagedObjectMappingOperationDataSource

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectCache = _managedObjectCache;
@synthesize operationQueue = _operationQueue;
@synthesize tracksInsertedObjects = _tracksInsertedObjects;
@synthesize mutableInsertedObjects = _mutableInsertedObjects;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext cache:(id<RKManagedObjectCaching>)managedObjectCache
{
    NSParameterAssert(managedObjectContext);
    
    self = [self init];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        self.managedObjectCache = managedObjectCache;
        self.mutableInsertedObjects = [NSMutableArray array];
        self.tracksInsertedObjects = NO;
    }
    
    return self;
}

- (void)dealloc
{
    [_managedObjectCache release];
    [_managedObjectContext release];
    [_operationQueue release];
    [_mutableInsertedObjects release];
    
    [super dealloc];
}

- (id)objectForMappableContent:(id)mappableContent mapping:(RKObjectMapping *)mapping
{
    NSAssert(mappableContent, @"Mappable data cannot be nil");
    NSAssert(self.managedObjectContext, @"%@ must be initialized with a managed object context.", [self class]);
    
    if (! [mapping isKindOfClass:[RKEntityMapping class]]) {
        return [[mapping.objectClass new] autorelease];
    }
    
    RKEntityMapping *entityMapping = (RKEntityMapping *)mapping;
    id object = nil;
    id primaryKeyValue = nil;
    NSString *primaryKeyAttribute;
    
    NSEntityDescription *entity = [entityMapping entity];
    RKAttributeMapping *primaryKeyAttributeMapping = nil;
    
    primaryKeyAttribute = [entityMapping primaryKeyAttribute];
    if (primaryKeyAttribute) {
        // If a primary key has been set on the object mapping, find the attribute mapping
        // so that we can extract any existing primary key from the mappable data
        for (RKAttributeMapping *attributeMapping in entityMapping.attributeMappings) {
            if ([attributeMapping.destinationKeyPath isEqualToString:primaryKeyAttribute]) {
                primaryKeyAttributeMapping = attributeMapping;
                break;
            }
        }
        
        // Get the primary key value out of the mappable data (if any)
        if ([primaryKeyAttributeMapping isMappingForKeyOfNestedDictionary]) {
            RKLogDebug(@"Detected use of nested dictionary key as primaryKey attribute...");
            primaryKeyValue = [[mappableContent allKeys] lastObject];
        } else {
            NSString* keyPathForPrimaryKeyElement = primaryKeyAttributeMapping.sourceKeyPath;
            if (keyPathForPrimaryKeyElement) {
                primaryKeyValue = [mappableContent valueForKeyPath:keyPathForPrimaryKeyElement];
            } else {
                RKLogWarning(@"Unable to find source attribute for primaryKeyAttribute '%@': unable to find existing object instances by primary key.", primaryKeyAttribute);
            }
        }
    }
    
    if (! self.managedObjectCache) {
        RKLogWarning(@"Performing managed object mapping with a nil managed object cache:\n"
                      "Unable to update existing object instances by primary key. Duplicate objects may be created.");
    }

    // If we have found the primary key attribute & value, try to find an existing instance to update
    if (primaryKeyAttribute && primaryKeyValue && NO == [primaryKeyValue isEqual:[NSNull null]]) {
        object = [self.managedObjectCache findInstanceOfEntity:entity
                                       withPrimaryKeyAttribute:primaryKeyAttribute
                                                         value:primaryKeyValue
                                        inManagedObjectContext:self.managedObjectContext];                
        
        if (object && [self.managedObjectCache respondsToSelector:@selector(didFetchObject:)]) {
            [self.managedObjectCache didFetchObject:object];
        }
    }
    
    if (object == nil) {
        object = [[[NSManagedObject alloc] initWithEntity:entity
                           insertIntoManagedObjectContext:self.managedObjectContext] autorelease];
        if (primaryKeyAttribute && primaryKeyValue && ![primaryKeyValue isEqual:[NSNull null]]) {
            [object setValue:primaryKeyValue forKey:primaryKeyAttribute];
        }
        
        if ([self.managedObjectCache respondsToSelector:@selector(didCreateObject:)]) {
            [self.managedObjectCache didCreateObject:object];
        }
        
        if (self.tracksInsertedObjects) {
            [self.mutableInsertedObjects addObject:object];
        }
    }
    
    return object;
}

/* 
 Mapping operations should be executed against managed object contexts with NSPrivateQueueConcurrencyType
 */
- (BOOL)executingConnectionOperationsWouldDeadlock
{
    return [NSThread isMainThread] && [self.managedObjectContext concurrencyType] == NSMainQueueConcurrencyType && self.operationQueue;
}

- (void)emitDeadlockWarningIfNecessary
{
    if ([self executingConnectionOperationsWouldDeadlock]) {
        RKLogWarning(@"Mapping operation was configured with a managedObjectContext with the NSMainQueueConcurrencyType"
                      " and given an operationQueue to perform background work. This configuration will lead to a deadlock with"
                      " the main queue waiting on the mapping to complete and the operationQueue waiting for access to the MOC."
                      " You should instead provide a managedObjectContext with the NSPrivateQueueConcurrencyType.");
    }
}

- (void)commitChangesForMappingOperation:(RKMappingOperation *)mappingOperation
{
    if ([mappingOperation.mapping isKindOfClass:[RKEntityMapping class]]) {
        [self emitDeadlockWarningIfNecessary];
        
        for (RKConnectionMapping *connectionMapping in [(RKEntityMapping *)mappingOperation.mapping connectionMappings]) {
            RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:mappingOperation.destinationObject
                                                                                                          connectionMapping:connectionMapping
                                                                                                         managedObjectCache:self.managedObjectCache];
            if (self.operationQueue) {
                [self.operationQueue addOperation:operation];
            } else {
                [operation start];
            }
            [operation release];
        }
    }
}

- (NSArray *)insertedObjects
{
    return [NSArray arrayWithArray:self.mutableInsertedObjects];
}

- (void)clearInsertedObjects
{
    self.mutableInsertedObjects = [NSMutableArray array];
}

@end
