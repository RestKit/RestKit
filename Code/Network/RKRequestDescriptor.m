//
//  RKRequestDescriptor.m
//  RestKit
//
//  Created by Blake Watters on 8/24/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//
//  Created by Blake Watters on 8/24/12.
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

#import "RKRequestDescriptor.h"
#import "RKObjectMapping.h"
#import "RKDynamicMapping.h"

static void RKAssertValidMappingForRequestDescriptor(RKMapping *mapping)
{
    if ([mapping isKindOfClass:[RKObjectMapping class]]) {
        if (! [[(RKObjectMapping *)mapping objectClass] isEqual:[NSMutableDictionary class]]) {
            [NSException raise:NSInvalidArgumentException format:@"`RKRequestDescriptor` objects must be initialized with a mapping whose target class is `NSMutableDictionary`, got '%@' (see `[RKObjectMapping requestMapping]`)", [(RKObjectMapping *)mapping objectClass]];
        }
    } else if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
        [[(RKDynamicMapping *)mapping objectMappings] enumerateObjectsUsingBlock:^(RKObjectMapping *objectMapping, NSUInteger idx, BOOL *stop) {
            if (! [objectMapping.objectClass isEqual:[NSMutableDictionary class]]) {
                [NSException raise:NSInvalidArgumentException format:@"`RKRequestDescriptor` objects may only be initialized with `RKDynamicMapping` objects containing `RKObjectMapping` objects whose target class is `NSMutableDictionary`, got '%@' (see `[RKObjectMapping requestMapping]`)", objectMapping.objectClass];
            }
        }];
    } else {
        [NSException raise:NSInvalidArgumentException format:@"Expected an instance of `RKObjectMapping` or `RKDynamicMapping`, instead got '%@'", [mapping class]];
    }
}

@interface RKRequestDescriptor ()

@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, strong, readwrite) Class objectClass;
@property (nonatomic, copy, readwrite) NSString *rootKeyPath;

@end

@implementation RKRequestDescriptor

+ (instancetype)requestDescriptorWithMapping:(RKMapping *)mapping objectClass:(Class)objectClass rootKeyPath:(NSString *)rootKeyPath
{
    NSParameterAssert(mapping);
    NSParameterAssert(objectClass);
    RKAssertValidMappingForRequestDescriptor(mapping);

    RKRequestDescriptor *requestDescriptor = [self new];
    requestDescriptor.mapping = mapping;
    requestDescriptor.objectClass = objectClass;
    requestDescriptor.rootKeyPath = rootKeyPath;
    return requestDescriptor;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p objectClass=%@ rootKeyPath=%@ : %@>",
            NSStringFromClass([self class]), self, NSStringFromClass(self.objectClass), self.rootKeyPath, self.mapping];
}

- (BOOL)matchesObject:(id)object
{
    return [object isKindOfClass:self.objectClass];
}

@end
