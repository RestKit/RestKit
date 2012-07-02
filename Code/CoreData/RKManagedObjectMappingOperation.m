//
//  RKManagedObjectMappingOperation.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
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

#import "RKManagedObjectMappingOperation.h"
#import "RKManagedObjectMapping.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKDynamicObjectMappingMatcher.h"
#import "RKManagedObjectCaching.h"
#import "RKManagedObjectStore.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@implementation RKManagedObjectMappingOperation

- (void)connectRelationship:(RKObjectConnectionMapping *)connectionMapping 
{
    RKLogTrace(@"Connecting relationship '%@'", connectionMapping.relationshipName);

    id relatedObject = [connectionMapping findConnected:self.destinationObject];

    if (relatedObject) {
        [self.destinationObject setValue:relatedObject forKeyPath:connectionMapping.relationshipName];
        RKLogDebug(@"Connected relationship '%@' to object '%@'", connectionMapping.relationshipName, relatedObject);
    } else {
        RKManagedObjectMapping *objectMapping = (RKManagedObjectMapping *) connectionMapping.mapping;
        RKLogDebug(@"Failed to find instance of '%@' to connect relationship '%@'", [[objectMapping entity] name], connectionMapping.relationshipName);
    }
}

- (void)connectRelationships 
{
    RKManagedObjectMapping *mapping = (RKManagedObjectMapping*)self.objectMapping;
    RKLogTrace(@"relationshipsAndPrimaryKeyAttributes: %@", mapping.connections);
    for (RKObjectConnectionMapping* connectionMapping in mapping.connections) {
        if (self.queue) {
            RKLogTrace(@"Enqueueing relationship connection using operation queue");
            __block RKManagedObjectMappingOperation *selfRef = self;
            [self.queue addOperationWithBlock:^{
                [selfRef connectRelationship:connectionMapping];
            }];
        } else {
            [self connectRelationship:connectionMapping];
        }
    }
}

- (BOOL)performMapping:(NSError **)error
{
    BOOL success = [super performMapping:error];
    if ([self.objectMapping isKindOfClass:[RKManagedObjectMapping class]]) {
        /**
         NOTE: Processing the pending changes here ensures that the managed object context generates observable
         callbacks that are important for maintaining any sort of cache that is consistent within a single
         object mapping operation. As the MOC is only saved when the aggregate operation is processed, we must
         manually invoke processPendingChanges to prevent recreating objects with the same primary key.
         See https://github.com/RestKit/RestKit/issues/661
         */
        [self connectRelationships];
    }
    return success;
}

@end
