//
//  RKTableViewCellMappings.m
//  RestKit
//
//  Created by Blake Watters on 8/9/11.
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

#import "RKTableViewCellMappings.h"

@implementation RKTableViewCellMappings

+ (id)cellMappings
{
    return [[self new] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        _cellMappings = [NSMutableDictionary new];
    }

    return self;
}

- (void)setCellMapping:(RKTableViewCellMapping *)cellMapping forClass:(Class)objectClass
{
    if ([_cellMappings objectForKey:objectClass]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:[NSString stringWithFormat:@"A tableViewCell mapping has already been registered for objects of type '%@'", NSStringFromClass(objectClass)]
                                     userInfo:nil];
    }

    [_cellMappings setObject:cellMapping forKey:objectClass];
}

- (RKTableViewCellMapping *)cellMappingForClass:(Class)objectClass
{
    // Exact match
    RKTableViewCellMapping *cellMapping = [_cellMappings objectForKey:objectClass];
    if (cellMapping) return cellMapping;

    // Subclass match
    for (Class cellClass in _cellMappings) {
        if ([objectClass isSubclassOfClass:cellClass]) {
            return [_cellMappings objectForKey:cellClass];
        }
    }

    return nil;
}

- (RKTableViewCellMapping *)cellMappingForObject:(id)object
{
    if ([object respondsToSelector:@selector(cellMapping)]) {
        // TODO: Trace logging...
        // TODO: This needs unit test coverage on the did select row case...
        RKTableViewCellMapping *cellMapping = [object cellMapping];
        if (cellMapping) return [object cellMapping];
    }

    return [self cellMappingForClass:[object class]];
}

@end
