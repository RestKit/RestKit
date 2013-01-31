//
//  RKConnectionDescription.m
//  RestKit
//
//  Created by Blake Watters on 11/20/12.
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

#import "RKConnectionDescription.h"
#import "RKConnectionDescriptionSubclass.h"

@implementation RKConnectionDescription

- (id)init
{
    if ([self class] == [RKConnectionDescription class]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. "
                                               "Use concrete subclass instead.",
                                               NSStringFromClass([self class])]
                                     userInfo:nil];
    }
    return [super init];
}

- (id)findRelatedObjectFor:(NSManagedObject *)managedObject inManagedObjectCache:(id<RKManagedObjectCaching>)managedObjectCache {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"%@ Don't call super implemenentation for %@. "
                                           "Use concrete subclass instead.",
                                           NSStringFromClass([self class]), NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (id)copyWithZone:(NSZone *)zone
{
    if ([self class] == [RKConnectionDescription class]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. "
                                               "Use concrete subclass instead.",
                                               NSStringFromClass([self class])]
                                     userInfo:nil];
    }
    
    return nil;
}

@end
