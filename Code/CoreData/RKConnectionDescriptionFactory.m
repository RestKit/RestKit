//
//  RKConnectionDescriptionFactory.m
//  RestKit
//
//  Created by Marius Rackwitz on 21.01.13.
//  Copyright (c) 2013 RestKit. All rights reserved.
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

#import "RKConnectionDescriptionFactory.h"

@implementation RKConnectionDescriptionFactory

static RKConnectionDescriptionFactory *sharedInstance;

+ (instancetype)sharedInstance
{
    if (!sharedInstance) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

- (RKForeignKeyConnectionDescription *)connectionWithRelationship:(NSRelationshipDescription *)relationship attributes:(NSDictionary *)attributes
{
    return [[RKForeignKeyConnectionDescription alloc] initWithRelationship:relationship attributes:attributes];
}

- (RKKeyPathConnectionDescription *)connectionWithRelationship:(NSRelationshipDescription *)relationship keyPath:(NSString *)keyPath
{
    return [[RKKeyPathConnectionDescription alloc] initWithRelationship:relationship keyPath:keyPath];
}

@end
