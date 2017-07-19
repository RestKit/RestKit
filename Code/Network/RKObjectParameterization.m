//
//  RKObjectParameterization.m
//  RestKit
//
//  Created by Blake Watters on 5/2/11.
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

#import "RKMIMETypes.h"
#import "RKSerialization.h"
#import "RKObjectParameterization.h"
#import "RKMIMETypeSerialization.h"
#import "RKLog.h"
#import "RKObjectMappingOperationDataSource.h"
#import "RKObjectMapping.h"
#import "RKMappingOperation.h"
#import "RKMappingErrors.h"
#import "RKPropertyInspector.h"
#import "RKValueTransformers.h"
#import "RKBooleanClass.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitNetwork

@interface RKObjectParameterization () <RKMappingOperationDelegate>
@property (nonatomic, strong) id object;
@property (nonatomic, strong) RKRequestDescriptor *requestDescriptor;

- (instancetype)initWithObject:(id)object requestDescriptor:(RKRequestDescriptor *)requestDescriptor;
- (NSDictionary *)mapObjectToParameters:(NSError **)error;

// Convenience methods
@property (nonatomic, readonly) RKObjectMapping *mapping;
@property (nonatomic, readonly) NSString *rootKeyPath;
@end

@implementation RKObjectParameterization

+ (NSDictionary *)parametersWithObject:(id)object requestDescriptor:(RKRequestDescriptor *)requestDescriptor error:(NSError **)error
{
    RKObjectParameterization *parameterization = [[self alloc] initWithObject:object requestDescriptor:requestDescriptor];
    return [parameterization mapObjectToParameters:error];
}

- (instancetype)initWithObject:(id)object requestDescriptor:(RKRequestDescriptor *)requestDescriptor
{
    NSParameterAssert(object);
    NSParameterAssert(requestDescriptor);
    
    self = [super init];
    if (self) {
        self.object = object;
        self.requestDescriptor = requestDescriptor;
    }
    return self;
}

- (RKMapping *)mapping
{
    return self.requestDescriptor.mapping;
}

- (NSString *)rootKeyPath
{
    return self.requestDescriptor.rootKeyPath;
}

- (NSDictionary *)mapObjectToParameters:(NSError **)error
{
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:self.object destinationObject:dictionary mapping:self.mapping];
    operation.dataSource = dataSource;
    operation.delegate = self;
    [operation start];
    if (operation.error) {
        if (operation.error.code == RKMappingErrorUnmappableRepresentation) {
            // If the mapped object is empty, return an empty dictionary and no error
            return self.rootKeyPath ? @{ self.rootKeyPath: @{} } : @{};
        }
        
        if (error) *error = operation.error;
        return nil;
    }

    // Optionally enclose the serialized object within a container...
    return self.rootKeyPath ? [NSMutableDictionary dictionaryWithObject:dictionary forKey:self.rootKeyPath] : dictionary;
}

#pragma mark - RKMappingOperationDelegate

- (void)mappingOperation:(RKMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKAttributeMapping *)mapping
{
    id transformedValue = nil;
    if (value == nil) {
        if (mapping.objectMapping.assignsDefaultValueForMissingAttributes) {
            // Serialize nil values as null
            transformedValue = [NSNull null];
        }
    } else if ([value isKindOfClass:[NSDate class]]) {
        [mapping.valueTransformer transformValue:value toValue:&transformedValue ofClass:[NSString class] error:nil];
    } else if ([value isKindOfClass:[NSDecimalNumber class]]) {
        // Precision numbers are serialized as strings to work around Javascript notation limits
        transformedValue = [(NSDecimalNumber *)value stringValue];
    } else if ([value isKindOfClass:[NSSet class]]) {
        // NSSets are not natively serializable, so let's just turn it into an NSArray
        transformedValue = [value allObjects];
    } else if ([value isKindOfClass:[NSOrderedSet class]]) {
        // NSOrderedSets are not natively serializable, so let's just turn it into an NSArray
        transformedValue = [value array];
    } else {
        Class propertyClass = RKPropertyInspectorGetClassForPropertyAtKeyPathOfObject(mapping.sourceKeyPath, operation.sourceObject);
        if ([propertyClass isSubclassOfClass:RK_BOOLEAN_CLASS]) {
            transformedValue = @([value boolValue]);
        }
    }

    if (transformedValue) {
        RKLogDebug(@"Serialized %@ value at keyPath to %@ (%@)", NSStringFromClass([value class]), NSStringFromClass([transformedValue class]), value);
        [operation.destinationObject setValue:transformedValue forKeyPath:keyPath];
    }
}

- (BOOL)mappingOperation:(RKMappingOperation *)operation shouldSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKPropertyMapping *)propertyMapping
{
    NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
    id currentValue = operation.destinationObject;
    for (NSString *key in keyPathComponents) {
        id value = [currentValue valueForKey:key];
        if (value == nil) {
            value = [NSMutableDictionary new];
            [currentValue setValue:value forKey:key];
        }
        currentValue = value;
    }
    return YES;
}

@end
