//
//  RKRelationshipConnectionOperation.m
//  RestKit
//
//  Created by Blake Watters on 7/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import <CoreData/CoreData.h>
#import "RKRelationshipConnectionOperation.h"
#import "RKConnectionDescription.h"
#import "RKEntityMapping.h"
#import "RKLog.h"
#import "RKManagedObjectCaching.h"
#import "RKObjectMappingMatcher.h"
#import "RKErrors.h"
#import "RKObjectUtilities.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

id RKMutableSetValueForRelationship(NSRelationshipDescription *relationship);
id RKMutableSetValueForRelationship(NSRelationshipDescription *relationship)
{
    if (! [relationship isToMany]) return nil;
    return [relationship isOrdered] ? [NSMutableOrderedSet orderedSet] : [NSMutableSet set];
}

static BOOL RKConnectionAttributeValuesIsNotConnectable(NSDictionary *attributeValues)
{
    return [[NSSet setWithArray:[attributeValues allValues]] isEqualToSet:[NSSet setWithObject:[NSNull null]]];
}

static NSDictionary *RKConnectionAttributeValuesWithObject(RKConnectionDescription *connection, NSManagedObject *managedObject)
{
    NSCAssert([connection isForeignKeyConnection], @"Only valid for a foreign key connection");
    NSMutableDictionary *destinationEntityAttributeValues = [NSMutableDictionary dictionaryWithCapacity:[connection.attributes count]];
    for (NSString *sourceAttribute in connection.attributes) {
        NSString *destinationAttribute = [connection.attributes objectForKey:sourceAttribute];
        id sourceValue = [managedObject valueForKey:sourceAttribute];
        [destinationEntityAttributeValues setValue:sourceValue ?: [NSNull null] forKey:destinationAttribute];
    }
    return RKConnectionAttributeValuesIsNotConnectable(destinationEntityAttributeValues) ? nil : destinationEntityAttributeValues;
}

@interface RKRelationshipConnectionOperation ()
@property (nonatomic, strong, readwrite) NSManagedObject *managedObject;
@property (nonatomic, strong, readwrite) NSArray *connections;
@property (nonatomic, strong, readwrite) id<RKManagedObjectCaching> managedObjectCache;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) NSMutableDictionary *connectedValuesByRelationshipName;
@property (nonatomic, copy) void (^connectionBlock)(RKRelationshipConnectionOperation *operation, RKConnectionDescription *connection, id connectedValue);

// Helpers
@property (weak, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@end

@implementation RKRelationshipConnectionOperation

- (id)initWithManagedObject:(NSManagedObject *)managedObject
                connections:(NSArray *)connections
         managedObjectCache:(id<RKManagedObjectCaching>)managedObjectCache
{
    NSParameterAssert(managedObject);
    NSAssert([managedObject isKindOfClass:[NSManagedObject class]], @"Relationship connection requires an instance of NSManagedObject");
    NSParameterAssert(connections);
    NSParameterAssert(managedObjectCache);
    self = [self init];
    if (self) {
        self.managedObject = managedObject;
        self.connections = connections;
        self.managedObjectCache = managedObjectCache;
    }

    return self;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.managedObject.managedObjectContext;
}

- (id)relationshipValueForConnection:(RKConnectionDescription *)connection withConnectionResult:(id)result
{
    // TODO: Replace with use of object mapping engine for type conversion

    // NOTE: This is a nasty hack to work around the fact that NSOrderedSet does not support key-value
    // collection operators. We try to detect and unpack a doubly wrapped collection
    if ([connection.relationship isToMany] && RKObjectIsCollectionOfCollections(result)) {
        id mutableSet = RKMutableSetValueForRelationship(connection.relationship);
        for (id<NSFastEnumeration> enumerable in result) {
            for (id object in enumerable) {
                [mutableSet addObject:object];
            }
        }

        return mutableSet;
    }

    if ([connection.relationship isToMany]) {
        if ([result isKindOfClass:[NSArray class]]) {
            if ([connection.relationship isOrdered]) {
                return [NSOrderedSet orderedSetWithArray:result];
            } else {
                return [NSSet setWithArray:result];
            }
        } else if ([result isKindOfClass:[NSSet class]]) {
            if ([connection.relationship isOrdered]) {
                return [NSOrderedSet orderedSetWithSet:result];
            } else {
                return result;
            }
        } else if ([result isKindOfClass:[NSOrderedSet class]]) {
            if ([connection.relationship isOrdered]) {
                return result;
            } else {
                return [(NSOrderedSet *)result set];
            }
        } else {
            if ([connection.relationship isOrdered]) {
                return [NSOrderedSet orderedSetWithObject:result];
            } else {
                return [NSSet setWithObject:result];
            }
        }
    }

    return result;
}

- (id)findConnectedValueForConnection:(RKConnectionDescription *)connection shouldConnect:(BOOL *)shouldConnectRelationship
{
    *shouldConnectRelationship = YES;
    id connectionResult = nil;
    if (connection.sourcePredicate && ![connection.sourcePredicate evaluateWithObject:self.managedObject]) return nil;
    
    if ([connection isForeignKeyConnection]) {
        NSDictionary *attributeValues = RKConnectionAttributeValuesWithObject(connection, self.managedObject);
        // If there are no attribute values available for connecting, skip the connection entirely
        if (! attributeValues) {
            *shouldConnectRelationship = NO;
            return nil;
        }
        NSSet *managedObjects = [self.managedObjectCache managedObjectsWithEntity:[connection.relationship destinationEntity]
                                                                  attributeValues:attributeValues
                                                           inManagedObjectContext:self.managedObjectContext];
        if (connection.destinationPredicate) managedObjects = [managedObjects filteredSetUsingPredicate:connection.destinationPredicate];
        if (!connection.includesSubentities) managedObjects = [managedObjects filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"entity == %@", [connection.relationship destinationEntity]]];
        if ([connection.relationship isToMany]) {
            connectionResult = managedObjects;
        } else {
            if ([managedObjects count] > 1) RKLogWarning(@"Retrieved %ld objects satisfying connection criteria for one-to-one relationship connection: only one object will be connected.", (long) [managedObjects count]);
            if ([managedObjects count]) connectionResult = [managedObjects anyObject];
        }
    } else if ([connection isKeyPathConnection]) {
        connectionResult = [self.managedObject valueForKeyPath:connection.keyPath];
    } else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"%@ Attempted to establish a relationship using a mapping that"
                                               " specifies neither a foreign key or a key path connection: %@",
                                               NSStringFromClass([self class]), connection]
                                     userInfo:nil];
    }

    return [self relationshipValueForConnection:connection withConnectionResult:connectionResult];
}

- (void)main
{
    for (RKConnectionDescription *connection in self.connections) {
        if (self.isCancelled || [self.managedObject isDeleted]) return;
        NSString *relationshipName = connection.relationship.name;
        RKLogTrace(@"Connecting relationship '%@' with mapping: %@", relationshipName, connection);
        
        BOOL shouldConnect = YES;
        // TODO: What I need to do is make all of this based on callbacks so I can jump in/out of the MOC queue
        id connectedValue = [self findConnectedValueForConnection:connection shouldConnect:&shouldConnect];
        [self.connectedValuesByRelationshipName setValue:(connectedValue ?: [NSNull null]) forKey:relationshipName];
        if (shouldConnect) {
            [self.managedObjectContext performBlockAndWait:^{
                if (self.isCancelled || [self.managedObject isDeleted]) return;
                @try {
                    [self.managedObject setValue:connectedValue forKeyPath:relationshipName];
                    RKLogDebug(@"Connected relationship '%@' to object '%@'", relationshipName, connectedValue);
                    if (self.connectionBlock) self.connectionBlock(self, connection, connectedValue);
                }
                @catch (NSException *exception) {
                    if ([[exception name] isEqualToString:NSObjectInaccessibleException]) {
                        // Object has been deleted
                        RKLogDebug(@"Rescued an `NSObjectInaccessibleException` exception while attempting to establish a relationship.");
                    } else {
                        [exception raise];
                    }
                }
            }];
        }
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p %@ in %@ using %@>",
            [self class], self, self.connections, self.managedObjectContext, self.managedObjectCache];
}

@end
