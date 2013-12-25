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

// TODO: Audit...
//static void RKAssertValidMappingForRequestDescriptor(RKMapping *mapping)
//{
//    if ([mapping isKindOfClass:[RKObjectMapping class]]) {
//        if (! [[(RKObjectMapping *)mapping objectClass] isEqual:[NSMutableDictionary class]]) {
//            [NSException raise:NSInvalidArgumentException format:@"`RKRequestDescriptor` objects must be initialized with a mapping whose target class is `NSMutableDictionary`, got '%@' (see `[RKObjectMapping requestMapping]`)", [(RKObjectMapping *)mapping objectClass]];
//        }
//    } else if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
//        [[(RKDynamicMapping *)mapping objectMappings] enumerateObjectsUsingBlock:^(RKObjectMapping *objectMapping, NSUInteger idx, BOOL *stop) {
//            if (! [objectMapping.objectClass isEqual:[NSMutableDictionary class]]) {
//                [NSException raise:NSInvalidArgumentException format:@"`RKRequestDescriptor` objects may only be initialized with `RKDynamicMapping` objects containing `RKObjectMapping` objects whose target class is `NSMutableDictionary`, got '%@' (see `[RKObjectMapping requestMapping]`)", objectMapping.objectClass];
//            }
//        }];
//    } else {
//        [NSException raise:NSInvalidArgumentException format:@"Expected an instance of `RKObjectMapping` or `RKDynamicMapping`, instead got '%@'", [mapping class]];
//    }
//}

extern NSString *RKStringDescribingHTTPMethods(RKHTTPMethodOptions method);

@interface RKRequestDescriptor ()

@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, strong, readwrite) Class objectClass;
@property (nonatomic, copy, readwrite) NSString *rootKeyPath;
@property (nonatomic, assign, readwrite) RKHTTPMethodOptions method;

@end

@implementation RKRequestDescriptor

+ (instancetype)requestDescriptorWithObjectClass:(Class)objectClass
                                         methods:(RKHTTPMethodOptions)methods
                                     rootKeyPath:(NSString *)rootKeyPath
                                         mapping:(RKMapping *)mapping
{
    return [[self alloc] initWithObjectClass:objectClass method:methods rootKeyPath:rootKeyPath mapping:mapping];
}

- (id)initWithObjectClass:(Class)objectClass
                   method:(RKHTTPMethodOptions)method
              rootKeyPath:(NSString *)rootKeyPath
                  mapping:(RKMapping *)mapping
{
    self = [super init];
    if (self) {
        self.objectClass = objectClass;
        self.method = method;
        self.rootKeyPath = rootKeyPath;
        self.mapping = mapping;
    }
    return self;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. "
                                           "Invoke `+ requestDescriptorWithObjectClass:methods:rootKeyPath:mapping:` instead.",
                                           NSStringFromClass([self class])]
                                 userInfo:nil];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p method=%@ objectClass=%@ rootKeyPath=%@ : %@>",
            NSStringFromClass([self class]), self, RKStringDescribingHTTPMethods(self.method), NSStringFromClass(self.objectClass), self.rootKeyPath, self.mapping];
}

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

- (NSUInteger)hash
{
    return NSUINTROTATE(NSUINTROTATE([self.mapping hash], NSUINT_BIT / 3) ^ [self.objectClass hash], NSUINT_BIT / 3) ^ [self.rootKeyPath hash];
}

- (BOOL)isEqual:(id)object
{
    if (self == object) return YES;
    if (object == nil) return NO;
    if (![object isKindOfClass:[RKRequestDescriptor class]]) return NO;

    RKRequestDescriptor *otherDescriptor = (RKRequestDescriptor *)object;
    return ([self.mapping isEqual:otherDescriptor.mapping] &&
            self.objectClass == otherDescriptor.objectClass &&
            self.method == otherDescriptor.method &&
            [self.rootKeyPath isEqualToString:otherDescriptor.rootKeyPath]);
}

@end
