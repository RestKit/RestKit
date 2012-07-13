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
#import "RKObjectMappingOperation.h"
#import "RKDynamicObjectMappingMatcher.h"
#import "RKManagedObjectCaching.h"
#import "RKMappingOperationQueue.h"
#import "RKEntityConnectionOperation.h"
#import "RKRelationshipConnectionOperation.h"

@interface RKManagedObjectMappingOperationDataSource ()
@property (nonatomic, retain, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readwrite) id<RKManagedObjectCaching> managedObjectCache;

@end

@implementation RKManagedObjectMappingOperationDataSource

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectCache = _managedObjectCache;
@synthesize operationQueue = _operationQueue;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext cache:(id<RKManagedObjectCaching>)managedObjectCache
{
    NSParameterAssert(managedObjectContext);
    NSParameterAssert(managedObjectCache);
    
    self = [self init];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        self.managedObjectCache = managedObjectCache;
    }
    
    return self;
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
    NSString* primaryKeyAttribute;
    
    NSEntityDescription* entity = [entityMapping entity];
    RKObjectAttributeMapping* primaryKeyAttributeMapping = nil;
    
    primaryKeyAttribute = [entityMapping primaryKeyAttribute];
    if (primaryKeyAttribute) {
        // If a primary key has been set on the object mapping, find the attribute mapping
        // so that we can extract any existing primary key from the mappable data
        for (RKObjectAttributeMapping* attributeMapping in entityMapping.attributeMappings) {
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
    }
    
    return object;
}

// TODO: Encapsulate the connection logic into a new object...
// The findConnected: etc methods from the connection mapping should live on the connector/connectionOperation

//- (void)connectRelationshipForManagedObject:(NSManagedObject *)managedObject connectionMapping:(RKConnectionMapping *)connectionMapping
//{
//    RKLogTrace(@"Connecting relationship '%@'", connectionMapping.relationshipName);
//    
//    id relatedObject = [connectionMapping findConnected:managedObject usingCache:self.managedObjectCache];    
//    if (relatedObject) {
//        [managedObject setValue:relatedObject forKeyPath:connectionMapping.relationshipName];
//        RKLogDebug(@"Connected relationship '%@' to object '%@'", connectionMapping.relationshipName, relatedObject);
//    } else {
//        RKEntityMapping *objectMapping = (RKEntityMapping *)connectionMapping.mapping;
//        RKLogDebug(@"Failed to find instance of '%@' to connect relationship '%@'", [[objectMapping entity] name], connectionMapping.relationshipName);
//    }
//}

//- (void)connectRelationshipsForManagedObject:(NSManagedObject *)managedObject entityMapping:(RKEntityMapping *)entityMapping
//{
//    RKLogTrace(@"Connecting relationships for managed object %@ using connection mappings: %@", managedObject, entityMapping.connections);
//    for (RKConnectionMapping *connectionMapping in entityMapping.connections) {
//        if (self.queue) {
//            RKLogTrace(@"Enqueueing relationship connection using operation queue");
//            __block RKManagedObjectMappingOperationDataSource *selfRef = self;
//            [self.queue addOperationWithBlock:^{
//                [selfRef connectRelationshipForManagedObject:managedObject connectionMapping:connectionMapping];
//            }];
//        } else {
//            [self connectRelationshipForManagedObject:managedObject connectionMapping:connectionMapping];
//        }
//    }
//}

/* 
 Mapping operations should be executed against managed object contexts
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

- (void)commitChangesForMappingOperation:(RKObjectMappingOperation *)mappingOperation
{
    if ([mappingOperation.objectMapping isKindOfClass:[RKEntityMapping class]]) {
        [self emitDeadlockWarningIfNecessary];
        
        NSLog(@"The destination object is: %@. isInserted = %d", mappingOperation.destinationObject, [mappingOperation.destinationObject isInserted]);
//        RKEntityConnectionOperation *operation = [[RKEntityConnectionOperation alloc] initWithManagedObject:mappingOperation.destinationObject
//                                                                                              entityMapping:(RKEntityMapping *)mappingOperation.objectMapping
//                                                                                         managedObjectCache:self.managedObjectCache];
        
        for (RKConnectionMapping *connectionMapping in [(RKEntityMapping *)mappingOperation.objectMapping connections]) {
            RKEntityConnectionOperation *operation = [[RKEntityConnectionOperation alloc] initWithManagedObject:mappingOperation.destinationObject
                                                                                                  entityMapping:(RKEntityMapping *)mappingOperation.objectMapping
                                                                                             managedObjectCache:self.managedObjectCache];
//            RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:mappingOperation.destinationObject
//                                                                                                          connectionMapping:connectionMapping
//                                                                                                         managedObjectCache:self.managedObjectCache];
            if (self.operationQueue) {
                [self.operationQueue addOperation:operation];
            } else {
                [operation start];
            }
            [operation release];
        }
        
//        [self connectRelationshipsForManagedObject:mappingOperation.destinationObject entityMapping:(RKEntityMapping *)mappingOperation.objectMapping];
    }
}

@end
