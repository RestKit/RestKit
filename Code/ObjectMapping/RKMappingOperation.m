//
//  RKMappingOperation.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
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

#import <objc/runtime.h>
#import "RKMappingOperation.h"
#import "RKMappingErrors.h"
#import "RKPropertyInspector.h"
#import "RKAttributeMapping.h"
#import "RKRelationshipMapping.h"
#import "RKErrors.h"
#import "RKLog.h"
#import "RKMappingOperationDataSource.h"
#import "RKObjectMappingOperationDataSource.h"
#import "RKDynamicMapping.h"
#import "RKObjectUtilities.h"
#import "RKValueTransformers.h"
#import "RKDictionaryUtilities.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitObjectMapping

extern NSString * const RKObjectMappingNestingAttributeKeyName;

/**
 This function ensures that attribute mappings apply cleanly to an `NSMutableDictionary` target class to support mapping to nested keyPaths. See issue #882
 */
static void RKSetIntermediateDictionaryValuesOnObjectForKeyPath(id object, NSString *keyPath)
{
    if (! [object isKindOfClass:[NSMutableDictionary class]]) return;
    NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
    if ([keyPathComponents count] > 1) {
        for (NSUInteger index = 0; index < [keyPathComponents count] - 1; index++) {
            NSString *intermediateKeyPath = [[keyPathComponents subarrayWithRange:NSMakeRange(0, index + 1)] componentsJoinedByString:@"."];
            if (! [object valueForKeyPath:intermediateKeyPath]) {
                [object setValue:[NSMutableDictionary dictionary] forKeyPath:intermediateKeyPath];
            }
        }
    }
}

static BOOL RKIsManagedObject(id object)
{
    Class managedObjectClass = NSClassFromString(@"NSManagedObject");
    return managedObjectClass && [object isKindOfClass:managedObjectClass];
}

// Returns the appropriate value for `nil` value of a primitive type
static id RKPrimitiveValueForNilValueOfClass(Class keyValueCodingClass)
{
    if ([keyValueCodingClass isSubclassOfClass:[NSNumber class]]) {
        return @(0);
    } else {
        return nil;
    }
}

// Key comes from: [[self.nestedAttributeSubstitution allKeys] lastObject] AND [[self.nestedAttributeSubstitution allValues] lastObject];
NSArray *RKApplyNestingAttributeValueToMappings(NSString *attributeName, id value, NSArray *propertyMappings);
NSArray *RKApplyNestingAttributeValueToMappings(NSString *attributeName, id value, NSArray *propertyMappings)
{
    if (!attributeName) return propertyMappings;

    NSString *searchString = [NSString stringWithFormat:@"{%@}", attributeName];
    NSString *replacementString = [NSString stringWithFormat:@"%@", value];
    NSMutableArray *nestedMappings = [NSMutableArray arrayWithCapacity:[propertyMappings count]];
    for (RKPropertyMapping *propertyMapping in propertyMappings) {
        NSString *sourceKeyPath = [propertyMapping.sourceKeyPath stringByReplacingOccurrencesOfString:searchString withString:replacementString];
        NSString *destinationKeyPath = [propertyMapping.destinationKeyPath stringByReplacingOccurrencesOfString:searchString withString:replacementString];
        if ([propertyMapping isKindOfClass:[RKAttributeMapping class]]) {
            [nestedMappings addObject:[RKAttributeMapping attributeMappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath]];
        } else if ([propertyMapping isKindOfClass:[RKRelationshipMapping class]]) {
            [nestedMappings addObject:[RKRelationshipMapping relationshipMappingFromKeyPath:sourceKeyPath
                                                                        toKeyPath:destinationKeyPath
                                                                      withMapping:[(RKRelationshipMapping *)propertyMapping mapping]]];
        }
    }
    
    return nestedMappings;
}

// Returns YES if there is a value present for at least one key path in the given collection
static BOOL RKObjectContainsValueForKeyPaths(id representation, NSArray *keyPaths)
{
    for (NSString *keyPath in keyPaths) {
        if ([representation valueForKeyPath:keyPath]) return YES;
    }
    return NO;
}

static NSString *const RKMetadataKey = @"@metadata";
static NSString *const RKMetadataKeyPathPrefix = @"@metadata.";
static NSString *const RKParentKey = @"@parent";
static NSString *const RKParentKeyPathPrefix = @"@parent.";
static NSString *const RKRootKey = @"@root";
static NSString *const RKRootKeyPathPrefix = @"@root.";

@interface RKMappingSourceObject : NSProxy
- (id)initWithObject:(id)object parentObject:(id)parentObject rootObject:(id)rootObject metadata:(NSDictionary *)metadata;
@end

@interface RKMappingSourceObject ()
@property (nonatomic, strong) id object;
@property (nonatomic, strong) id parentObject;
@property (nonatomic, strong) id rootObject;
@property (nonatomic, strong) NSDictionary *metadata;
@end

@implementation RKMappingSourceObject

- (id)initWithObject:(id)object parentObject:(id)parentObject rootObject:(id)rootObject metadata:(NSDictionary *)metadata
{
    self.object = object;
    self.parentObject = parentObject;
    self.rootObject = rootObject;
    self.metadata = metadata;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    return [self.object methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation invokeWithTarget:self.object];
}

- (id)valueForKey:(NSString *)key
{
    if ([key isEqualToString:RKMetadataKey]) {
        return self.metadata;
    } else if ([key isEqualToString:RKParentKey]) {
        return self.parentObject;
    } else if ([key isEqualToString:RKRootKey]) {
        return self.rootObject;
    } else {
        return [self.object valueForKey:key];
    }
}

/**
 NOTE: We implement `valueForKeyPath:` on the proxy instead of using `forwardInvocation:` because the OS X runtime fails to appropriately handle scalar boxing/unboxing, resulting in incorrect metadata mappings. Proxying the method directly produces the expected results on both OS X and iOS [sbw - 2/1/2012]
 */
- (id)valueForKeyPath:(NSString *)keyPath
{
    if ([keyPath hasPrefix:RKMetadataKeyPathPrefix]) {
        NSString *metadataKeyPath = [keyPath substringFromIndex:[RKMetadataKeyPathPrefix length]];
        return [self.metadata valueForKeyPath:metadataKeyPath];
    } else if ([keyPath hasPrefix:RKParentKeyPathPrefix]) {
        NSString *parentKeyPath = [keyPath substringFromIndex:[RKParentKeyPathPrefix length]];
        return [self.parentObject valueForKeyPath:parentKeyPath];
    } else if ([keyPath hasPrefix:RKRootKeyPathPrefix]) {
        NSString *rootKeyPath = [keyPath substringFromIndex:[RKRootKeyPathPrefix length]];
        return [self.rootObject valueForKeyPath:rootKeyPath];
    } else {
        return [self.object valueForKeyPath:keyPath];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@)", [self.object description], self.metadata];
}

- (Class)class
{
    return [self.object class];
}

@end

@interface RKMappingInfo ()
@property (nonatomic, assign, readwrite) NSUInteger collectionIndex;
@property (nonatomic, strong) NSMutableSet *mutablePropertyMappings;
@property (nonatomic, strong) NSMutableDictionary *mutableRelationshipMappingInfo;

- (id)initWithObjectMapping:(RKObjectMapping *)objectMapping dynamicMapping:(RKDynamicMapping *)dynamicMapping;
- (void)addPropertyMapping:(RKPropertyMapping *)propertyMapping;
@end

@implementation RKMappingInfo

- (id)initWithObjectMapping:(RKObjectMapping *)objectMapping dynamicMapping:(RKDynamicMapping *)dynamicMapping
{
    self = [self init];
    if (self) {
        _objectMapping = objectMapping;
        _dynamicMapping = dynamicMapping;
        _mutablePropertyMappings = [NSMutableSet setWithCapacity:[objectMapping.propertyMappings count]];
        _mutableRelationshipMappingInfo = [NSMutableDictionary dictionaryWithCapacity:[objectMapping.relationshipMappings count]];
    }
    return self;
}

- (NSSet *)propertyMappings
{
    return [self.mutablePropertyMappings copy];
}

- (NSDictionary *)relationshipMappingInfo
{
    return [self.mutableRelationshipMappingInfo copy];
}

- (void)addPropertyMapping:(RKPropertyMapping *)propertyMapping
{
    [self.mutablePropertyMappings addObject:propertyMapping];
}

- (void)addMappingInfo:(RKMappingInfo *)mappingInfo forRelationshipMapping:(RKRelationshipMapping *)relationshipMapping
{
    NSMutableArray *arrayOfMappingInfo = [self.mutableRelationshipMappingInfo objectForKey:relationshipMapping.destinationKeyPath];
    if (arrayOfMappingInfo) {
        [arrayOfMappingInfo addObject:mappingInfo];
    } else {
        arrayOfMappingInfo = [NSMutableArray arrayWithObject:mappingInfo];
        [self.mutableRelationshipMappingInfo setObject:arrayOfMappingInfo forKey:relationshipMapping.destinationKeyPath];
    }
}

- (id)objectForKeyedSubscript:(id)key
{
    for (RKPropertyMapping *propertyMapping in self.mutablePropertyMappings) {
        if ([propertyMapping.destinationKeyPath isEqualToString:key]) {
            return propertyMapping;
        }
    }
    return nil;
}

@end

@interface RKMappingOperation ()
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, strong, readwrite) id sourceObject;
@property (nonatomic, strong, readwrite) id parentSourceObject;
@property (nonatomic, strong, readwrite) id rootSourceObject;
@property (nonatomic, strong, readwrite) id destinationObject;
@property (nonatomic, strong) NSDictionary *nestedAttributeSubstitution;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) RKObjectMapping *objectMapping; // The concrete mapping
@property (nonatomic, strong) NSArray *nestedAttributeMappings;
@property (nonatomic, strong) RKMappingInfo *mappingInfo;
@end

@implementation RKMappingOperation

- (id)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject mapping:(RKMapping *)objectOrDynamicMapping
{
    NSAssert(sourceObject != nil, @"Cannot perform a mapping operation without a sourceObject object");
    NSAssert(objectOrDynamicMapping != nil, @"Cannot perform a mapping operation without a mapping");

    self = [super init];
    if (self) {
        self.sourceObject = sourceObject;
        self.rootSourceObject = sourceObject;
        self.destinationObject = destinationObject;
        self.mapping = objectOrDynamicMapping;
    }

    return self;
}

- (id)parentObjectForRelationshipMapping:(RKRelationshipMapping *)mapping
{
    id parentSourceObject = self.sourceObject;

    NSArray *sourceKeyComponents = [mapping.sourceKeyPath componentsSeparatedByString:@"."];
    if (sourceKeyComponents.count > 1)
    {
        for (NSString *key in [sourceKeyComponents subarrayWithRange:NSMakeRange(0, sourceKeyComponents.count - 1)])
        {
            parentSourceObject = [[RKMappingSourceObject alloc] initWithObject:[parentSourceObject valueForKey:key]
                                                                  parentObject:parentSourceObject
                                                                    rootObject:self.rootSourceObject
                                                                      metadata:self.metadata];
        }
    }

    return parentSourceObject;
}

- (id)destinationObjectForMappingRepresentation:(id)representation parentRepresentation:(id)parentRepresentation withMapping:(RKMapping *)mapping inRelationship:(RKRelationshipMapping *)relationshipMapping
{
    RKObjectMapping *concreteMapping = nil;
    if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
        concreteMapping = [(RKDynamicMapping *)mapping objectMappingForRepresentation:representation];
        if (! concreteMapping) {
            RKLogDebug(@"Unable to determine concrete object mapping from dynamic mapping %@ with which to map object representation: %@", mapping, representation);
            return nil;
        }
    } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
        concreteMapping = (RKObjectMapping *)mapping;
    }
    
    NSDictionary *dictionaryRepresentation = [representation isKindOfClass:[NSDictionary class]] ? representation : @{ [NSNull null] : representation };
    NSDictionary *metadata = RKDictionaryByMergingDictionaryWithDictionary(self.metadata, @{ @"mapping": @{ @"parentObject": (self.destinationObject ?: [NSNull null]) } });
    RKMappingSourceObject *sourceObject = [[RKMappingSourceObject alloc] initWithObject:dictionaryRepresentation parentObject:parentRepresentation rootObject:self.rootSourceObject metadata:metadata];
    return [self.dataSource mappingOperation:self targetObjectForRepresentation:(NSDictionary *)sourceObject withMapping:concreteMapping inRelationship:relationshipMapping];
}

- (BOOL)validateValue:(id *)value atKeyPath:(NSString *)keyPath
{
    BOOL success = YES;

    if (self.objectMapping.performsKeyValueValidation && [self.destinationObject respondsToSelector:@selector(validateValue:forKeyPath:error:)]) {
        NSError *validationError;
        success = [self.destinationObject validateValue:value forKeyPath:keyPath error:&validationError];
        if (!success) {
            self.error = validationError;
            if (validationError) {
                RKLogError(@"Validation failed while mapping attribute at key path '%@' to value %@. Error: %@", keyPath, *value, [validationError localizedDescription]);
                RKLogValidationError(validationError);
            } else {
                RKLogWarning(@"Destination object %@ rejected attribute value %@ for keyPath %@. Skipping...", self.destinationObject, *value, keyPath);
            }
        }
    }

    return success;
}

- (BOOL)shouldSetValue:(id *)value forKeyPath:(NSString *)keyPath usingMapping:(RKPropertyMapping *)propertyMapping
{
    if ([self.delegate respondsToSelector:@selector(mappingOperation:shouldSetValue:forKeyPath:usingMapping:)]) {
        return [self.delegate mappingOperation:self shouldSetValue:*value forKeyPath:keyPath usingMapping:propertyMapping];
    }
    
    // Always set the properties
    if ([self.dataSource respondsToSelector:@selector(mappingOperationShouldSetUnchangedValues:)] && [self.dataSource mappingOperationShouldSetUnchangedValues:self]) return YES;
    
    id currentValue = [self.destinationObject valueForKeyPath:keyPath];
    if (currentValue == [NSNull null]) {
        currentValue = nil;
    }

    /*
     WTF - This workaround should not be necessary, but I have been unable to replicate
     the circumstances that trigger it in a unit test to fix elsewhere. The proper place
     to handle it is in transformValue:atKeyPath:toType:

     See issue & pull request: https://github.com/RestKit/RestKit/pull/436
     */
    if (*value == [NSNull null]) *value = nil;

    if (nil == currentValue && nil == *value) {
        // Both are nil
        return NO;
    } else if (nil == *value || nil == currentValue) {
        // One is nil and the other is not
        return [self validateValue:value atKeyPath:keyPath];
    }

    if (! RKObjectIsEqualToObject(*value, currentValue)) {
        // Validate value for key
        return [self validateValue:value atKeyPath:keyPath];
    }
    return NO;
}

- (NSArray *)applyNestingToMappings:(NSArray *)propertyMappings
{
    NSString *attributeName = [[self.nestedAttributeSubstitution allKeys] lastObject];
    id value = [[self.nestedAttributeSubstitution allValues] lastObject];
    return self.nestedAttributeSubstitution ? RKApplyNestingAttributeValueToMappings(attributeName, value, propertyMappings) : propertyMappings;
}

- (NSArray *)nestedAttributeMappings
{
    if (!_nestedAttributeMappings) _nestedAttributeMappings = [self applyNestingToMappings:self.objectMapping.attributeMappings];
    return _nestedAttributeMappings;
}

- (NSArray *)simpleAttributeMappings
{
    NSMutableArray *mappings = [NSMutableArray array];
    for (RKAttributeMapping *mapping in self.nestedAttributeMappings) {
        if ([mapping.sourceKeyPath rangeOfString:@"."].location == NSNotFound) {
            [mappings addObject:mapping];
        }
    }

    return mappings;
}

- (NSArray *)keyPathAttributeMappings
{
    NSMutableArray *mappings = [NSMutableArray array];
    for (RKAttributeMapping *mapping in self.nestedAttributeMappings) {
        if ([mapping.sourceKeyPath rangeOfString:@"."].location != NSNotFound) {
            [mappings addObject:mapping];
        }
    }

    return mappings;
}

- (NSArray *)relationshipMappings
{
    return [self applyNestingToMappings:self.objectMapping.relationshipMappings];
}

- (BOOL)transformValue:(id)inputValue toValue:(__autoreleasing id *)outputValue withPropertyMapping:(RKPropertyMapping *)propertyMapping error:(NSError *__autoreleasing *)error
{
    Class transformedValueClass = propertyMapping.propertyValueClass ?: [self.objectMapping classForKeyPath:propertyMapping.destinationKeyPath];
    if (! transformedValueClass) {
        *outputValue = inputValue;
        return YES;
    }
    RKLogTrace(@"Found transformable value at keyPath '%@'. Transforming from class '%@' to '%@'", propertyMapping.sourceKeyPath, NSStringFromClass([inputValue class]), NSStringFromClass(transformedValueClass));
    BOOL success = [propertyMapping.valueTransformer transformValue:inputValue toValue:outputValue ofClass:transformedValueClass error:error];
    if (! success) RKLogError(@"Failed transformation of value at keyPath '%@' to representation of type '%@': %@", propertyMapping.sourceKeyPath, transformedValueClass, *error);
    return success;
}

- (void)applyAttributeMapping:(RKAttributeMapping *)attributeMapping withValue:(id)value
{
    if ([self.delegate respondsToSelector:@selector(mappingOperation:didFindValue:forKeyPath:mapping:)]) {
        [self.delegate mappingOperation:self didFindValue:value forKeyPath:attributeMapping.sourceKeyPath mapping:attributeMapping];
    }
    RKLogTrace(@"Mapping attribute value keyPath '%@' to '%@'", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath);

    id transformedValue = nil;
    NSError *error = nil;
    if (! [self transformValue:value toValue:&transformedValue withPropertyMapping:attributeMapping error:&error]) return;
    
    // If we have a nil value for a primitive property, we need to coerce it into a KVC usable value or bail out
    if (transformedValue == nil && RKPropertyInspectorIsPropertyAtKeyPathOfObjectPrimitive(attributeMapping.destinationKeyPath, self.destinationObject)) {
        RKLogDebug(@"Detected `nil` value transformation for primitive property at keyPath '%@'", attributeMapping.destinationKeyPath);
        transformedValue = RKPrimitiveValueForNilValueOfClass([self.objectMapping classForKeyPath:attributeMapping.destinationKeyPath]);
        if (! transformedValue) {
            RKLogTrace(@"Skipped mapping of attribute value from keyPath '%@ to keyPath '%@' -- Unable to transform `nil` into primitive value representation", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath);
            return;
        }
    }

    RKSetIntermediateDictionaryValuesOnObjectForKeyPath(self.destinationObject, attributeMapping.destinationKeyPath);
    
    // Ensure that the value is different
    if ([self shouldSetValue:&transformedValue forKeyPath:attributeMapping.destinationKeyPath usingMapping:attributeMapping]) {
        RKLogTrace(@"Mapped attribute value from keyPath '%@' to '%@'. Value: %@", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath, transformedValue);
        
        if (attributeMapping.destinationKeyPath) {
            [self.destinationObject setValue:transformedValue forKeyPath:attributeMapping.destinationKeyPath];
        } else {
            if ([self.destinationObject isKindOfClass:[NSMutableDictionary class]] && [transformedValue isKindOfClass:[NSDictionary class]]) {
                [self.destinationObject setDictionary:transformedValue];
            } else {
                [NSException raise:NSInvalidArgumentException format:@"Unable to set value for destination object of type '%@': Can only directly set destination object for `NSMutableDictionary` targets. (transformedValue=%@)", [self.destinationObject class], transformedValue];
            }
        }
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didSetValue:forKeyPath:usingMapping:)]) {
            [self.delegate mappingOperation:self didSetValue:transformedValue forKeyPath:attributeMapping.destinationKeyPath usingMapping:attributeMapping];
        }
    } else {
        RKLogTrace(@"Skipped mapping of attribute value from keyPath '%@ to keyPath '%@' -- value is unchanged (%@)", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath, transformedValue);
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
            [self.delegate mappingOperation:self didNotSetUnchangedValue:transformedValue forKeyPath:attributeMapping.destinationKeyPath usingMapping:attributeMapping];
        }
    }
    [self.mappingInfo addPropertyMapping:attributeMapping];
}

// Return YES if we mapped any attributes
- (BOOL)applyAttributeMappings:(NSArray *)attributeMappings
{
    // If we have a nesting substitution value, we have already succeeded
    BOOL appliedMappings = (self.nestedAttributeSubstitution != nil);

    if (!self.objectMapping.performsKeyValueValidation) {
        RKLogDebug(@"Key-value validation is disabled for mapping, skipping...");
    }

    for (RKAttributeMapping *attributeMapping in attributeMappings) {
        if ([self isCancelled]) return NO;

        if ([attributeMapping.sourceKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName] || [attributeMapping.destinationKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName]) {
            RKLogTrace(@"Skipping attribute mapping for special keyPath '%@'", attributeMapping.sourceKeyPath);
            continue;
        }

        id value = (attributeMapping.sourceKeyPath == nil) ? self.sourceObject : [self.sourceObject valueForKeyPath:attributeMapping.sourceKeyPath];
        if (value) {
            appliedMappings = YES;
            [self applyAttributeMapping:attributeMapping withValue:value];
        } else {
            if ([self.delegate respondsToSelector:@selector(mappingOperation:didNotFindValueForKeyPath:mapping:)]) {
                [self.delegate mappingOperation:self didNotFindValueForKeyPath:attributeMapping.sourceKeyPath mapping:attributeMapping];
            }
            RKLogTrace(@"Did not find mappable attribute value keyPath '%@'", attributeMapping.sourceKeyPath);

            // Optionally set the default value for missing values
            if (self.objectMapping.assignsDefaultValueForMissingAttributes) {
                [self.destinationObject setValue:[self.objectMapping defaultValueForAttribute:attributeMapping.destinationKeyPath]
                                      forKeyPath:attributeMapping.destinationKeyPath];
                RKLogTrace(@"Setting nil for missing attribute value at keyPath '%@'", attributeMapping.sourceKeyPath);
            }
        }

        // Fail out if an error has occurred
        if (self.error) break;
    }

    return appliedMappings;
}

- (BOOL)mapNestedObject:(id)anObject toObject:(id)anotherObject withRelationshipMapping:(RKRelationshipMapping *)relationshipMapping metadata:(NSDictionary *)metadata
{
    NSAssert(anObject, @"Cannot map nested object without a nested source object");
    NSAssert(anotherObject, @"Cannot map nested object without a destination object");
    NSAssert(relationshipMapping, @"Cannot map a nested object relationship without a relationship mapping");
    NSError *error = nil;

    RKLogTrace(@"Performing nested object mapping using mapping %@ for data: %@", relationshipMapping, anObject);
    NSDictionary *subOperationMetadata = RKDictionaryByMergingDictionaryWithDictionary(self.metadata, metadata);
    RKMappingOperation *subOperation = [[RKMappingOperation alloc] initWithSourceObject:anObject destinationObject:anotherObject mapping:relationshipMapping.mapping];
    subOperation.dataSource = self.dataSource;
    subOperation.delegate = self.delegate;
    subOperation.metadata = subOperationMetadata;
    subOperation.parentSourceObject = [self parentObjectForRelationshipMapping:relationshipMapping];
    subOperation.rootSourceObject = self.rootSourceObject;
    [subOperation start];
    
    if (subOperation.error) {
        RKLogWarning(@"WARNING: Failed mapping nested object: %@", [error localizedDescription]);
    } else {
        [self.mappingInfo addPropertyMapping:relationshipMapping];
        [self.mappingInfo addMappingInfo:subOperation.mappingInfo forRelationshipMapping:relationshipMapping];
    }

    return YES;
}

- (BOOL)applyReplaceAssignmentPolicyForRelationshipMapping:(RKRelationshipMapping *)relationshipMapping
{
    if (relationshipMapping.assignmentPolicy == RKReplaceAssignmentPolicy) {
        if ([self.dataSource respondsToSelector:@selector(mappingOperation:deleteExistingValueOfRelationshipWithMapping:error:)]) {
            NSError *error = nil;
            BOOL success = [self.dataSource mappingOperation:self deleteExistingValueOfRelationshipWithMapping:relationshipMapping error:&error];
            if (! success) {
                RKLogError(@"Failed to delete existing value of relationship mapped with RKReplaceAssignmentPolicy: %@", error);
                self.error = error;
                return NO;
            }
        } else {
            RKLogWarning(@"Requested mapping with `RKReplaceAssignmentPolicy` assignment policy, but the data source does not support it. Mapping has proceeded identically to the `RKSetAssignmentPolicy`.");
        }
    }
    
    return YES;
}

- (BOOL)mapOneToOneRelationshipWithValue:(id)value mapping:(RKRelationshipMapping *)relationshipMapping
{
    // One to one relationship
    RKLogDebug(@"Mapping one to one relationship value at keyPath '%@' to '%@'", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath);
    
    if (relationshipMapping.assignmentPolicy == RKUnionAssignmentPolicy) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Invalid assignment policy: cannot union a one-to-one relationship." };
        self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorInvalidAssignmentPolicy userInfo:userInfo];
        return NO;
    }

    id parentSourceObject = [self parentObjectForRelationshipMapping:relationshipMapping];
    id destinationObject = [self destinationObjectForMappingRepresentation:value parentRepresentation:parentSourceObject withMapping:relationshipMapping.mapping inRelationship:relationshipMapping];
    if (! destinationObject) {
        RKLogDebug(@"Mapping %@ declined mapping for representation %@: returned `nil` destination object.", relationshipMapping.mapping, destinationObject);
        return NO;
    }
    [self mapNestedObject:value toObject:destinationObject withRelationshipMapping:relationshipMapping metadata:@{ @"mapping": @{ @"collectionIndex": [NSNull null] } }];

    // If the relationship has changed, set it
    if ([self shouldSetValue:&destinationObject forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping]) {
        if (! [self applyReplaceAssignmentPolicyForRelationshipMapping:relationshipMapping]) {
            return NO;
        }
        
        RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
        [self.destinationObject setValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath];
    } else {
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
            [self.delegate mappingOperation:self didNotSetUnchangedValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping];
        }
    }

    return YES;
}

- (BOOL)mapCoreDataToManyRelationshipValue:(id)valueForRelationship withMapping:(RKRelationshipMapping *)relationshipMapping
{
    if (! RKIsManagedObject(self.destinationObject)) return NO;

    RKLogTrace(@"Mapping a to-many relationship for an `NSManagedObject`. About to apply value via mutable[Set|Array]ValueForKey");
    if ([valueForRelationship isKindOfClass:[NSSet class]]) {
        RKLogTrace(@"Mapped `NSSet` relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, valueForRelationship);
        NSMutableSet *destinationSet = [self.destinationObject mutableSetValueForKeyPath:relationshipMapping.destinationKeyPath];
        [destinationSet setSet:valueForRelationship];
    } else if ([valueForRelationship isKindOfClass:[NSArray class]]) {
        RKLogTrace(@"Mapped `NSArray` relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, valueForRelationship);
        NSMutableArray *destinationArray = [self.destinationObject mutableArrayValueForKeyPath:relationshipMapping.destinationKeyPath];
        [destinationArray setArray:valueForRelationship];
    } else if ([valueForRelationship isKindOfClass:[NSOrderedSet class]]) {
        RKLogTrace(@"Mapped `NSOrderedSet` relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, valueForRelationship);
        [self.destinationObject setValue:valueForRelationship forKeyPath:relationshipMapping.destinationKeyPath];
    }

    return YES;
}

- (BOOL)mapOneToManyRelationshipWithValue:(id)value mapping:(RKRelationshipMapping *)relationshipMapping
{
    // One to many relationship
    RKLogDebug(@"Mapping one to many relationship value at keyPath '%@' to '%@'", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath);

    NSMutableArray *relationshipCollection = [NSMutableArray arrayWithCapacity:[value count]];
    if (RKObjectIsCollectionOfCollections(value)) {
        RKLogWarning(@"WARNING: Detected a relationship mapping for a collection containing another collection. This is probably not what you want. Consider using a KVC collection operator (such as @unionOfArrays) to flatten your mappable collection.");
        RKLogWarning(@"Key path '%@' yielded collection containing another collection rather than a collection of objects: %@", relationshipMapping.sourceKeyPath, value);
    }
    
    if (relationshipMapping.assignmentPolicy == RKUnionAssignmentPolicy) {
        RKLogDebug(@"Mapping relationship with union assignment policy: constructing combined relationship value.");
        id existingObjects = [self.destinationObject valueForKeyPath:relationshipMapping.destinationKeyPath] ?: @[];
        NSArray *existingObjectsArray = nil;
        NSError *error = nil;
        [[RKValueTransformer defaultValueTransformer] transformValue:existingObjects toValue:&existingObjectsArray ofClass:[NSArray class] error:&error];
        [relationshipCollection addObjectsFromArray:existingObjectsArray];
    }
    else if (relationshipMapping.assignmentPolicy == RKReplaceAssignmentPolicy) {
        if (! [self applyReplaceAssignmentPolicyForRelationshipMapping:relationshipMapping]) {
            return NO;
        }
    }

    [value enumerateObjectsUsingBlock:^(id nestedObject, NSUInteger collectionIndex, BOOL *stop) {
        id parentSourceObject = [self parentObjectForRelationshipMapping:relationshipMapping];
        id mappableObject = [self destinationObjectForMappingRepresentation:nestedObject parentRepresentation:parentSourceObject withMapping:relationshipMapping.mapping inRelationship:relationshipMapping];
        if (mappableObject) {
            if ([self mapNestedObject:nestedObject toObject:mappableObject withRelationshipMapping:relationshipMapping metadata:@{ @"mapping": @{ @"collectionIndex": @(collectionIndex) } }]) {
                [relationshipCollection addObject:mappableObject];
            }
        } else {
            RKLogDebug(@"Mapping %@ declined mapping for representation %@: returned `nil` destination object.", relationshipMapping.mapping, nestedObject);
        }
    }];

    id valueForRelationship = nil;
    NSError *error = nil;
    if (! [self transformValue:relationshipCollection toValue:&valueForRelationship withPropertyMapping:relationshipMapping error:&error]) return NO;

    // If the relationship has changed, set it
    if ([self shouldSetValue:&valueForRelationship forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping]) {
        if (! [self mapCoreDataToManyRelationshipValue:valueForRelationship withMapping:relationshipMapping]) {
            RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, valueForRelationship);
            [self.destinationObject setValue:valueForRelationship forKeyPath:relationshipMapping.destinationKeyPath];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
            [self.delegate mappingOperation:self didNotSetUnchangedValue:valueForRelationship forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping];
        }

        return NO;
    }

    return YES;
}

- (BOOL)applyRelationshipMappings
{
    NSAssert(self.dataSource, @"Cannot perform relationship mapping without a data source");
    NSMutableArray *mappingsApplied = [NSMutableArray array];

    for (RKRelationshipMapping *relationshipMapping in [self relationshipMappings]) {
        if ([self isCancelled]) return NO;
        
        id value = nil;
        if (relationshipMapping.sourceKeyPath) {
            value = [self.sourceObject valueForKeyPath:relationshipMapping.sourceKeyPath];
        } else {
            // The nil source keyPath indicates that we want to map directly from the parent representation
            value = self.sourceObject;
            RKObjectMapping *objectMapping = nil;
            
            if ([relationshipMapping.mapping isKindOfClass:[RKObjectMapping class]]) {
                objectMapping = (RKObjectMapping *)relationshipMapping.mapping;
            } else if ([relationshipMapping.mapping isKindOfClass:[RKDynamicMapping class]]) {
                objectMapping = [(RKDynamicMapping *)relationshipMapping.mapping objectMappingForRepresentation:value];
            }
            
            if (! objectMapping) continue; // Mapping declined
            NSArray *propertyKeyPaths = [relationshipMapping valueForKeyPath:@"mapping.propertyMappings.sourceKeyPath"];
            if (! RKObjectContainsValueForKeyPaths(value, propertyKeyPaths)) {
                continue;
            }
        }

        // Track that we applied this mapping
        [mappingsApplied addObject:relationshipMapping];

        if (value == nil) {
            RKLogDebug(@"Did not find mappable relationship value keyPath '%@'", relationshipMapping.sourceKeyPath);
            if (! self.objectMapping.assignsNilForMissingRelationships) continue;
        }
        
        if (value == [NSNull null]) {
            RKLogDebug(@"Found null value at keyPath '%@'", relationshipMapping.sourceKeyPath);
            value = nil;
        }

        // nil out the property if necessary
        if (value == nil) {
            Class relationshipClass = [self.objectMapping classForKeyPath:relationshipMapping.destinationKeyPath];
            BOOL mappingToCollection = RKClassIsCollection(relationshipClass);
            if (relationshipMapping.assignmentPolicy == RKUnionAssignmentPolicy && mappingToCollection) {
                // Unioning `nil` with the existing value is functionally equivalent to doing nothing, so just continue
                continue;
            } else if (relationshipMapping.assignmentPolicy == RKUnionAssignmentPolicy) {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Invalid assignment policy: cannot union a one-to-one relationship." };
                self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorInvalidAssignmentPolicy userInfo:userInfo];
                continue;
            } else if (relationshipMapping.assignmentPolicy == RKReplaceAssignmentPolicy) {
                if (! [self applyReplaceAssignmentPolicyForRelationshipMapping:relationshipMapping]) {
                    continue;
                }
            }

            if ([self shouldSetValue:&value forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping]) {
                RKLogTrace(@"Setting nil for relationship value at keyPath '%@'", relationshipMapping.sourceKeyPath);
                [self.destinationObject setValue:value forKeyPath:relationshipMapping.destinationKeyPath];
            }

            continue;
        }

        // Handle case where incoming content is collection represented by a dictionary
        if (relationshipMapping.mapping.forceCollectionMapping) {
            // If we have forced mapping of a dictionary, map each subdictionary
            if ([value isKindOfClass:[NSDictionary class]]) {
                RKLogDebug(@"Collection mapping forced for NSDictionary, mapping each key/value independently...");
                NSArray *objectsToMap = [NSMutableArray arrayWithCapacity:[value count]];
                for (id key in value) {
                    NSDictionary *dictionaryToMap = [NSDictionary dictionaryWithObject:[value valueForKey:key] forKey:key];
                    [(NSMutableArray *)objectsToMap addObject:dictionaryToMap];
                }
                value = objectsToMap;
            } else {
                RKLogWarning(@"Collection mapping forced but mappable objects is of type '%@' rather than NSDictionary", NSStringFromClass([value class]));
            }
        }

        // Handle case where incoming content is a single object, but we want a collection
        Class relationshipClass = [self.objectMapping classForKeyPath:relationshipMapping.destinationKeyPath];
        BOOL mappingToCollection = RKClassIsCollection(relationshipClass);
        if (mappingToCollection && !RKObjectIsCollection(value)) {
            Class orderedSetClass = NSClassFromString(@"NSOrderedSet");
            RKLogDebug(@"Asked to map a single object into a collection relationship. Transforming to an instance of: %@", NSStringFromClass(relationshipClass));
            if ([relationshipClass isSubclassOfClass:[NSArray class]]) {
                value = [relationshipClass arrayWithObject:value];
            } else if ([relationshipClass isSubclassOfClass:[NSSet class]]) {
                value = [relationshipClass setWithObject:value];
            } else if (orderedSetClass && [relationshipClass isSubclassOfClass:orderedSetClass]) {
                value = [relationshipClass orderedSetWithObject:value];
            } else {
                RKLogWarning(@"Failed to transform single object");
            }
        }

        BOOL setValueForRelationship;
        if (RKObjectIsCollection(value)) {
            setValueForRelationship = [self mapOneToManyRelationshipWithValue:value mapping:relationshipMapping];
        } else {
            setValueForRelationship = [self mapOneToOneRelationshipWithValue:value mapping:relationshipMapping];
        }

        if (! setValueForRelationship) continue;

        // Notify the delegate
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didSetValue:forKeyPath:usingMapping:)]) {
            id setValue = [self.destinationObject valueForKeyPath:relationshipMapping.destinationKeyPath];
            [self.delegate mappingOperation:self didSetValue:setValue forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping];
        }

        // Fail out if a validation error has occurred
        if (self.error) break;
    }

    return [mappingsApplied count] > 0;
}

- (void)applyNestedMappings
{
    RKAttributeMapping *attributeMapping = [self.objectMapping mappingForSourceKeyPath:RKObjectMappingNestingAttributeKeyName];
    if (attributeMapping) {
        RKLogDebug(@"Found nested mapping definition to attribute '%@'", attributeMapping.destinationKeyPath);
        id attributeValue = [[self.sourceObject allKeys] lastObject];
        if (attributeValue) {
            RKLogDebug(@"Found nesting value of '%@' for attribute '%@'", attributeValue, attributeMapping.destinationKeyPath);
            self.nestedAttributeSubstitution = @{ attributeMapping.destinationKeyPath: attributeValue };
            [self applyAttributeMapping:attributeMapping withValue:attributeValue];
        } else {
            RKLogWarning(@"Unable to find nesting value for attribute '%@'", attributeMapping.destinationKeyPath);
        }
    }
    
    // Serialization
    attributeMapping = [self.objectMapping mappingForDestinationKeyPath:RKObjectMappingNestingAttributeKeyName];
    if (attributeMapping) {
        RKLogDebug(@"Found nested mapping definition to attribute '%@'", attributeMapping.destinationKeyPath);
        id attributeValue = [self.sourceObject valueForKeyPath:attributeMapping.sourceKeyPath];
        if (attributeValue) {
            RKLogDebug(@"Found nesting value of '%@' for attribute '%@'", attributeValue, attributeMapping.sourceKeyPath);
            self.nestedAttributeSubstitution = @{ attributeMapping.sourceKeyPath: attributeValue };
        } else {
            RKLogWarning(@"Unable to find nesting value for attribute '%@'", attributeMapping.destinationKeyPath);
        }
    }
}

- (void)cancel
{
    [super cancel];
    RKLogDebug(@"Mapping operation cancelled: %@", self);
}

- (void)main
{
    if ([self isCancelled]) return;

    // Handle metadata
    self.sourceObject = [[RKMappingSourceObject alloc] initWithObject:self.sourceObject parentObject:self.parentSourceObject rootObject:self.rootSourceObject metadata:self.metadata];

    RKLogDebug(@"Starting mapping operation...");
    RKLogTrace(@"Performing mapping operation: %@", self);
    
    if (! self.destinationObject) {
        self.destinationObject = [self destinationObjectForMappingRepresentation:self.sourceObject parentRepresentation:self.parentSourceObject withMapping:self.mapping inRelationship:nil];
        if (! self.destinationObject) {
            RKLogDebug(@"Mapping operation failed: Given nil destination object and unable to instantiate a destination object for mapping.");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Cannot perform a mapping operation with a nil destination object." };
            self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorNilDestinationObject userInfo:userInfo];
            return;
        }
    }
    
    // Determine the concrete mapping if we were initialized with a dynamic mapping
    if ([self.mapping isKindOfClass:[RKDynamicMapping class]]) {
        self.objectMapping = [(RKDynamicMapping *)self.mapping objectMappingForRepresentation:self.sourceObject];
        if (! self.objectMapping) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"A dynamic mapping failed to return a concrete object mapping matching the representation being mapped." };
            self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorUnableToDetermineMapping userInfo:userInfo];
            return;
        }
        RKLogDebug(@"RKObjectMappingOperation was initialized with a dynamic mapping. Determined concrete mapping = %@", self.objectMapping);

        if ([self.delegate respondsToSelector:@selector(mappingOperation:didSelectObjectMapping:forDynamicMapping:)]) {
            [self.delegate mappingOperation:self didSelectObjectMapping:self.objectMapping forDynamicMapping:(RKDynamicMapping *)self.mapping];
        }
        self.mappingInfo = [[RKMappingInfo alloc] initWithObjectMapping:self.objectMapping dynamicMapping:(RKDynamicMapping *)self.mapping];
    } else if ([self.mapping isKindOfClass:[RKObjectMapping class]]) {
        self.objectMapping = (RKObjectMapping *)self.mapping;
        self.mappingInfo = [[RKMappingInfo alloc] initWithObjectMapping:self.objectMapping dynamicMapping:nil];
    }
    
    BOOL canSkipMapping = [self.dataSource respondsToSelector:@selector(mappingOperationShouldSkipPropertyMapping:)] && [self.dataSource mappingOperationShouldSkipPropertyMapping:self];
    if (! canSkipMapping) {
        [self applyNestedMappings];
        if ([self isCancelled]) return;
        BOOL mappedSimpleAttributes = [self applyAttributeMappings:[self simpleAttributeMappings]];
        if ([self isCancelled]) return;
        BOOL mappedRelationships = [[self relationshipMappings] count] ? [self applyRelationshipMappings] : NO;
        if ([self isCancelled]) return;
        // NOTE: We map key path attributes last to allow you to map across the object graphs for objects created/updated by the relationship mappings
        BOOL mappedKeyPathAttributes = [self applyAttributeMappings:[self keyPathAttributeMappings]];
        
        if (!mappedSimpleAttributes && !mappedRelationships && !mappedKeyPathAttributes) {
            // We did not find anything to do
            RKLogDebug(@"Mapping operation did not find any mappable values for the attribute and relationship mappings in the given object representation");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"No mappable values found for any of the attributes or relationship mappings" };
            self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorUnmappableRepresentation userInfo:userInfo];
        }
    
        // We did some mapping work, if there's no error let's commit our changes to the data source
        if (self.error == nil) {
            if ([self.dataSource respondsToSelector:@selector(commitChangesForMappingOperation:error:)]) {
                NSError *error = nil;
                BOOL success = [self.dataSource commitChangesForMappingOperation:self error:&error];
                if (! success) {
                    self.error = error;
                }
            }
        }
    }

    if (self.error) {
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didFailWithError:)]) {
            [self.delegate mappingOperation:self didFailWithError:self.error];
        }

        RKLogDebug(@"Failed mapping operation: %@", [self.error localizedDescription]);
    } else {
        RKLogDebug(@"Finished mapping operation successfully...");
    }
}

- (BOOL)performMapping:(NSError **)error
{
    [self start];
    if (error) *error = self.error;
    return self.error == nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p> for '%@' object. Mapping values from object %@ to object %@ with object mapping %@",
            [self class], self, NSStringFromClass([self.destinationObject class]), self.sourceObject, self.destinationObject, self.objectMapping];
}

@end
