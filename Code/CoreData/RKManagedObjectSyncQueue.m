//
//  RKManagedObjectSyncQueue.m
//  RestKit
//
//  Created by Evan Cordell on 2/16/12.
//  Copyright (c) 2012 RestKit.
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

#import "RKManagedObjectSyncQueue.h"

@implementation RKManagedObjectSyncQueue

@dynamic queuePosition;
@dynamic syncMethod;
@dynamic syncMode;
@dynamic objectIDString;
@dynamic className;
@dynamic objectRoute;

+ (NSEntityDescription *)entityDescription {
    //Add queue to core data model before persistant store is created
    //TODO: Check if exists before creating new entity. This doesn't seem necessary (Core Data handles internally?)
    NSEntityDescription *syncQueue = [[[NSEntityDescription alloc] init] autorelease];
    [syncQueue setName: @"RKManagedObjectSyncQueue"];
    [syncQueue setManagedObjectClassName: @"RKManagedObjectSyncQueue"];
    [syncQueue setAbstract:NO];
    
    NSAttributeDescription *queuePositionAttribute = [[NSAttributeDescription alloc] init];
    [queuePositionAttribute setName:@"queuePosition"];
    [queuePositionAttribute setAttributeType:NSInteger32AttributeType];
    [queuePositionAttribute setOptional:NO];
    [queuePositionAttribute setDefaultValue:[NSNumber numberWithInteger:0]];
    
    NSAttributeDescription *syncMethodAttribute = [[NSAttributeDescription alloc] init];
    [syncMethodAttribute setName:@"syncMethod"];
    [syncMethodAttribute setAttributeType:NSInteger16AttributeType];
    [syncMethodAttribute setOptional:NO];
    [syncMethodAttribute setDefaultValue:[NSNumber numberWithInteger:0]];
    
    NSAttributeDescription *syncModeAttribute = [[NSAttributeDescription alloc] init];
    [syncModeAttribute setName:@"syncMode"];
    [syncModeAttribute setAttributeType:NSInteger16AttributeType];
    [syncModeAttribute setOptional:NO];
    [syncModeAttribute setDefaultValue:[NSNumber numberWithInteger:0]];
    
    NSAttributeDescription *objectIDStringAttribute = [[NSAttributeDescription alloc] init];
    [objectIDStringAttribute setName:@"objectIDString"];
    [objectIDStringAttribute setAttributeType:NSStringAttributeType];
    [objectIDStringAttribute setOptional:NO];
    [objectIDStringAttribute setDefaultValue:@""];
    
    NSAttributeDescription *classNameStringAttribute = [[NSAttributeDescription alloc] init];
    [classNameStringAttribute setName:@"className"];
    [classNameStringAttribute setAttributeType:NSStringAttributeType];
    [classNameStringAttribute setOptional:NO];
    [classNameStringAttribute setDefaultValue:@""];
    
    NSAttributeDescription *objectRouteAttribute = [[NSAttributeDescription alloc] init];
    [objectRouteAttribute setName:@"objectRoute"];
    [objectRouteAttribute setAttributeType:NSStringAttributeType];
    [objectRouteAttribute setOptional:YES];
    [objectRouteAttribute setDefaultValue:@""];
    
    [syncQueue setProperties:[NSArray arrayWithObjects:queuePositionAttribute, syncMethodAttribute, syncModeAttribute, objectIDStringAttribute, classNameStringAttribute, objectRouteAttribute, nil]];
    
    [queuePositionAttribute release];
    [syncMethodAttribute release];
    [syncModeAttribute release];
    [objectIDStringAttribute release];
    [classNameStringAttribute release];
    [objectRouteAttribute release];
  
    return syncQueue;
}

@end
