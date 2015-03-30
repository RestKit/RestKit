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

#pragma mark - Mapping utilities

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
        return @0;
    } else {
        return nil;
    }
}

// Key comes from: nestedAttributeSubstitutionKey AND nestedAttributeSubstitutionValue;
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
        RKPropertyMapping *nestedPropertyMapping = nil;
        if ([propertyMapping isKindOfClass:[RKAttributeMapping class]]) {
            nestedPropertyMapping = [RKAttributeMapping attributeMappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath];
        } else if ([propertyMapping isKindOfClass:[RKRelationshipMapping class]]) {
            nestedPropertyMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:sourceKeyPath
                                                                                toKeyPath:destinationKeyPath
                                                                              withMapping:[(RKRelationshipMapping *)propertyMapping mapping]];
        }
        nestedPropertyMapping.propertyValueClass = propertyMapping.propertyValueClass;
        nestedPropertyMapping.valueTransformer = propertyMapping.valueTransformer;
        if (nestedPropertyMapping) [nestedMappings addObject:nestedPropertyMapping];
    }
    
    return nestedMappings;
}

// Returns YES if there is a value present for at least one key path in the given collection
static BOOL RKObjectContainsValueForMappings(id representation, NSArray *propertyMappings)
{
    for (RKPropertyMapping *mapping in propertyMappings) {
        NSString *keyPath = mapping.sourceKeyPath;
        if (keyPath && [representation valueForKeyPath:keyPath]) return YES;
    }
    return NO;
}

#pragma mark - Metadata utilities

static NSString *const RKMetadataKey = @"@metadata";
static NSString *const RKMetadataKeyPathPrefix = @"@metadata.";
static NSString *const RKParentKey = @"@parent";
static NSString *const RKParentKeyPathPrefix = @"@parent.";
static NSString *const RKRootKey = @"@root";
static NSString *const RKRootKeyPathPrefix = @"@root.";
static NSString *const RKSelfKey = @"self";
static NSString *const RKSelfKeyPathPrefix = @"self.";

/**
 Inserts up to two objects a the start of the metadata list.  metadata1 will be at the front if both are provided.
 */
static NSArray *RKInsertInMetadataList(NSArray *list, id metadata1, id metadata2)
{
    if (metadata1 == nil && metadata2 == nil)
        return list;
    NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:list];
    if (metadata2)
        [newArray insertObject:metadata2 atIndex:0];
    if (metadata1)
        [newArray insertObject:metadata1 atIndex:0];
    return newArray;
}

@interface RKMappingSourceObject : NSObject
- (instancetype)initWithObject:(id)object parentObject:(id)parentObject rootObject:(id)rootObject metadata:(NSArray *)metadata;
- (id)metadataValueForKey:(NSString *)key;
- (id)metadataValueForKeyPath:(NSString *)keyPath;
@end

/**
 Class used in the single case of RKMappingSourceObject needing to return a single object
 for the "@metadata" key, which a special implementation of -valueForKeyPath:
 to iterate over the list of metadata dictionaries (which RKMappingSourceObject usually does).
 This usually only happens from the parentObjectForRelationshipMapping: implementation, but
 in case it does this class provides the implementation.
 */
@interface RKMetadataWrapper : NSObject
- (instancetype)initWithMappingSource:(RKMappingSourceObject *)source NS_DESIGNATED_INITIALIZER;
@property (nonatomic, strong) RKMappingSourceObject *mappingSource;
@end

@implementation RKMetadataWrapper

- (instancetype)initWithMappingSource:(RKMappingSourceObject *)source {
    if (self = [super init]) {
        self.mappingSource = source;
    }
    return self;
}

- (id)valueForKey:(NSString *)key
{
    return [self.mappingSource metadataValueForKey:key];
}
- (id)valueForKeyPath:(NSString *)keyPath
{
    return [self.mappingSource metadataValueForKeyPath:keyPath];
}
@end

/**
 Class meant to represent parts of the "mapping" sub-dictionary of the "@metadata" keys, but
 being more efficient to create than actual NSDictionary instances.  We can add any object properties
 to this class, and if non-nil that value will be used, otherwise it is a passthrough.
 */
@interface RKMappingMetadata : NSObject
@property (nonatomic) BOOL inValueForKeyPath;
@property (nonatomic) id parentObject;
@end

@implementation RKMappingMetadata

- (id)valueForKeyPath:(NSString *)keyPath
{
    static NSString *mappingPrefix = @"mapping.";

    /* We only allow paths with a "mapping." prefix, to simulate being a nested object */
    if ([keyPath hasPrefix:mappingPrefix]) {
        self.inValueForKeyPath = YES;
        id value = [super valueForKeyPath:[keyPath substringFromIndex:[mappingPrefix length]]];
        self.inValueForKeyPath = NO;
        return value;
    }
    
    return nil;
}

/* Only return values from valueForKey: if we are being routed from valueForKeyPath:.  This
 avoids us from returning value values from say "@metadata.collectionIndex" without the mapping prefix.
 */
- (id)valueForKey:(NSString *)key
{
    return self.inValueForKeyPath? [super valueForKey:key] : nil;
}

/* Return nil for any unknown keys, so the next object in the metadata list gets checked */
- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

@end

/**
 Subclass of RKMappingMetadata for use for holding the collectionIndex during a to-many mapping operation.
 Needs to be a subclass since the scalar property cannot return nil from valueForKey, so this can only
 be used when the collectionIndex is definitely set.
 */
@interface RKMappingIndexMetadata : RKMappingMetadata
@property (nonatomic) NSUInteger collectionIndex;
@end

@implementation RKMappingIndexMetadata
@end


@interface RKMappingSourceObject ()
@property (nonatomic, strong) id object;
@property (nonatomic, strong) id parentObject;
@property (nonatomic, strong) id rootObject;
@property (nonatomic, strong) NSArray *metadataList;
@end

@implementation RKMappingSourceObject

- (instancetype)initWithObject:(id)object parentObject:(id)parentObject rootObject:(id)rootObject metadata:(NSArray *)metadata
{
    self = [self init];
    if (self) {
        _object = object;
        _parentObject = parentObject;
        _rootObject = rootObject;
        _metadataList = metadata;
    }
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    return [_object methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation invokeWithTarget:_object];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _object;
}

- (id)metadataValueForKey:(NSString *)key
{
    for (NSDictionary *dict in self.metadataList)
    {
        id val = [dict valueForKey:key];
        if (val != nil) return val;
    }
    
    return nil;
}

- (id)metadataValueForKeyPath:(NSString *)keyPath
{
    for (NSDictionary *dict in self.metadataList)
    {
        id val = [dict valueForKeyPath:keyPath];
        if (val != nil) return val;
    }
    
    return nil;
}

- (id)valueForKey:(NSString *)key
{
    /* Using firstChar as a small performance enhancement -- one check can avoid several isEqual: calls */
    unichar firstChar = [key length] > 0 ? [key characterAtIndex:0] : 0;

    if (firstChar == 's' && [key isEqualToString:RKSelfKey]) {
        return _object;
    } else if (firstChar != '@') {
        return [_object valueForKey:key];
    } else if ([key isEqualToString:RKMetadataKey]) {
        return [[RKMetadataWrapper alloc] initWithMappingSource:self];
    } else if ([key isEqualToString:RKParentKey]) {
        return self.parentObject;
    } else if ([key isEqualToString:RKRootKey]) {
        return self.rootObject;
    } else {
        return [_object valueForKey:key];
    }
}

/**
 NOTE: We implement `valueForKeyPath:` on the proxy instead of using `forwardInvocation:` because the OS X runtime fails to appropriately handle scalar boxing/unboxing, resulting in incorrect metadata mappings. Proxying the method directly produces the expected results on both OS X and iOS [sbw - 2/1/2012]
 */
- (id)valueForKeyPath:(NSString *)keyPath
{
    /* Using firstChar as a small performance enhancement -- one check can avoid several hasPrefix calls */
    unichar firstChar = [keyPath length] > 0 ? [keyPath characterAtIndex:0] : 0;

    if (firstChar == 's' && [keyPath hasPrefix:RKSelfKeyPathPrefix]) {
        NSString *selfKeyPath = [keyPath substringFromIndex:[RKSelfKeyPathPrefix length]];
        return [_object valueForKeyPath:selfKeyPath];
    } else if (firstChar != '@') {
        return [_object valueForKeyPath:keyPath];
    } else if ([keyPath hasPrefix:RKMetadataKeyPathPrefix]) {
        NSString *metadataKeyPath = [keyPath substringFromIndex:[RKMetadataKeyPathPrefix length]];
        return [self metadataValueForKeyPath:metadataKeyPath];
    } else if ([keyPath hasPrefix:RKParentKeyPathPrefix]) {
        NSString *parentKeyPath = [keyPath substringFromIndex:[RKParentKeyPathPrefix length]];
        return [self.parentObject valueForKeyPath:parentKeyPath];
    } else if ([keyPath hasPrefix:RKRootKeyPathPrefix]) {
        NSString *rootKeyPath = [keyPath substringFromIndex:[RKRootKeyPathPrefix length]];
        return [self.rootObject valueForKeyPath:rootKeyPath];
    } else {
        return [_object valueForKeyPath:keyPath];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@)", [self.object description], self.metadataList];
}

- (Class)class
{
    return [_object class];
}

- (BOOL)isKindOfClass:(Class)aClass
{
    return [_object isKindOfClass:aClass];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [_object respondsToSelector:aSelector];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return [_object conformsToProtocol:aProtocol];
}

- (Class)rk_classForPropertyAtKeyPath:(NSString *)keyPath isPrimitive:(BOOL *)isPrimitive
{
    return [_object rk_classForPropertyAtKeyPath:keyPath isPrimitive:isPrimitive];
}

@end


#pragma mark - RKMappingInfo

@interface RKMappingInfo ()
@property (nonatomic, assign, readwrite) NSUInteger collectionIndex;
@property (nonatomic, strong) NSMutableSet *mutablePropertyMappings;
@property (nonatomic, strong) NSMutableDictionary *mutableRelationshipMappingInfo;

- (instancetype)initWithObjectMapping:(RKObjectMapping *)objectMapping dynamicMapping:(RKDynamicMapping *)dynamicMapping;
- (void)addPropertyMapping:(RKPropertyMapping *)propertyMapping;
@end

@implementation RKMappingInfo

- (instancetype)initWithObjectMapping:(RKObjectMapping *)objectMapping dynamicMapping:(RKDynamicMapping *)dynamicMapping
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
    NSMutableArray *arrayOfMappingInfo = (self.mutableRelationshipMappingInfo)[relationshipMapping.destinationKeyPath];
    if (arrayOfMappingInfo) {
        [arrayOfMappingInfo addObject:mappingInfo];
    } else {
        arrayOfMappingInfo = [NSMutableArray arrayWithObject:mappingInfo];
        (self.mutableRelationshipMappingInfo)[relationshipMapping.destinationKeyPath] = arrayOfMappingInfo;
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

#pragma mark - RKMappingOperation

@interface RKMappingOperation ()
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, strong, readwrite) id sourceObject;
@property (nonatomic, strong, readwrite) id parentSourceObject;
@property (nonatomic, strong, readwrite) id rootSourceObject;
@property (nonatomic, strong, readwrite) id destinationObject;
@property (nonatomic, strong, readwrite) NSArray *metadataList;
@property (nonatomic, strong) NSString *nestedAttributeSubstitutionKey;
@property (nonatomic, strong) id nestedAttributeSubstitutionValue;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) RKObjectMapping *objectMapping; // The concrete mapping
@property (nonatomic, strong) NSArray *nestedAttributeMappings;
@property (nonatomic, strong) NSArray *simpleAttributeMappings;
@property (nonatomic, strong) NSArray *keyPathAttributeMappings;
@property (nonatomic, strong) NSArray *relationshipMappings;
@property (nonatomic, strong) RKMappingInfo *mappingInfo;
@property (nonatomic, getter=isCancelled) BOOL cancelled;
@property (nonatomic) BOOL collectsMappingInfo;
@property (nonatomic) BOOL shouldSetUnchangedValues;
@property (nonatomic, readwrite, getter=isNewDestinationObject) BOOL newDestinationObject;
@end

@implementation RKMappingOperation

- (instancetype)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject mapping:(RKMapping *)objectOrDynamicMapping
{
    return [self initWithSourceObject:sourceObject destinationObject:destinationObject mapping:objectOrDynamicMapping metadataList:nil];
}

- (instancetype)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject mapping:(RKMapping *)objectOrDynamicMapping metadataList:(NSArray *)metadataList
{
    NSAssert(sourceObject != nil, @"Cannot perform a mapping operation without a sourceObject object");
    NSAssert(objectOrDynamicMapping != nil, @"Cannot perform a mapping operation without a mapping");

    self = [super init];
    if (self) {
        self.sourceObject = sourceObject;
        self.rootSourceObject = sourceObject;
        self.destinationObject = destinationObject;
        self.mapping = objectOrDynamicMapping;
        self.metadataList = metadataList;
    }

    return self;
}

- (id)parentObjectForRelationshipMapping:(RKRelationshipMapping *)mapping
{
    id parentSourceObject = self.sourceObject;
    NSString *sourceKeyPath = mapping.sourceKeyPath;

    NSRange lastDotRange = [sourceKeyPath rangeOfString:@"." options:NSBackwardsSearch|NSLiteralSearch];
    if (lastDotRange.length > 0)
    {
        NSString *parentKey = [sourceKeyPath substringToIndex:lastDotRange.location];
        id rootObject = self.rootSourceObject;
        NSArray *metadata = self.metadataList;
        for (NSString *key in [parentKey componentsSeparatedByString:@"."])
        {
            parentSourceObject = [[RKMappingSourceObject alloc] initWithObject:[parentSourceObject valueForKey:key]
                                                                  parentObject:parentSourceObject
                                                                    rootObject:rootObject
                                                                      metadata:metadata];
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
    
    id destinationObject = nil;
    id dataSource = self.dataSource;
    if ([dataSource respondsToSelector:@selector(mappingOperation:targetObjectForMapping:inRelationship:)])
    {
        destinationObject = [dataSource mappingOperation:self targetObjectForMapping:concreteMapping inRelationship:relationshipMapping];
    }
    
    if (destinationObject == nil)
    {
        NSDictionary *dictionaryRepresentation = [representation isKindOfClass:[NSDictionary class]] ? representation : @{ [NSNull null] : representation };
        RKMappingMetadata *parentMetadata = [RKMappingMetadata new];
        parentMetadata.parentObject = self.destinationObject ?: [NSNull null];
        NSArray *metadata = RKInsertInMetadataList(self.metadataList, parentMetadata, nil);
        RKMappingSourceObject *sourceObject = [[RKMappingSourceObject alloc] initWithObject:dictionaryRepresentation parentObject:parentRepresentation rootObject:self.rootSourceObject metadata:metadata];
        destinationObject = [dataSource mappingOperation:self targetObjectForRepresentation:(NSDictionary *)sourceObject withMapping:concreteMapping inRelationship:relationshipMapping];
    }

    return destinationObject;
}

- (BOOL)validateValue:(id *)value atKeyPath:(NSString *)keyPath
{
    BOOL success = YES;

    if (self.objectMapping.performsKeyValueValidation) {
        id destinationObject = self.destinationObject;
        
        if ([destinationObject respondsToSelector:@selector(validateValue:forKeyPath:error:)]) {
            NSError *validationError;
            success = [destinationObject validateValue:value forKeyPath:keyPath error:&validationError];
            if (!success) {
                self.error = validationError;
                if (validationError) {
                    RKLogError(@"Validation failed while mapping attribute at key path '%@' to value. Error: %@", keyPath, [validationError localizedDescription]);
                    RKLogValidationError(validationError);
                } else {
                    RKLogWarning(@"Destination object %@ rejected attribute value for keyPath %@. Skipping...", self.destinationObject, keyPath);
                }
                RKLogDebug(@"(Value for key path '%@': %@)", keyPath, *value);
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
    if (self.shouldSetUnchangedValues) {
        return [self validateValue:value atKeyPath:keyPath];
    }
    
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
    if (self.nestedAttributeSubstitutionKey == nil) return propertyMappings;
    
    return RKApplyNestingAttributeValueToMappings(self.nestedAttributeSubstitutionKey, self.nestedAttributeSubstitutionValue, propertyMappings);
}

- (void)cacheMappingsIfNeeded
{
    if (!_nestedAttributeMappings)
    {
        RKObjectMapping *mapping = self.objectMapping;

        if (self.nestedAttributeSubstitutionKey == nil) {
            _relationshipMappings = mapping.relationshipMappings;
            _nestedAttributeMappings = mapping.attributeMappings;
            _simpleAttributeMappings = mapping.keyAttributeMappings;
            _keyPathAttributeMappings = mapping.keyPathAttributeMappings;
        }
        else {
            _nestedAttributeMappings = [self applyNestingToMappings:mapping.attributeMappings];
            _relationshipMappings = [self applyNestingToMappings:mapping.relationshipMappings];
            NSMutableArray *simpleList = [[NSMutableArray alloc] initWithCapacity:[_nestedAttributeMappings count]];
            NSMutableArray *keyPathList = [[NSMutableArray alloc] initWithCapacity:[_nestedAttributeMappings count]];
            
            // The nested substitution may have changed which properties are simple vs keyPath, so we have to
            // re-check based on the nesting result.
            for (RKPropertyMapping *mapping in _nestedAttributeMappings) {
                BOOL isSimple = [mapping.sourceKeyPath rangeOfString:@"." options:NSLiteralSearch].length == 0;
                NSMutableArray *arrayToAdd = isSimple? simpleList : keyPathList;
                [arrayToAdd addObject:mapping];
            }
            
            _simpleAttributeMappings = simpleList;
            _keyPathAttributeMappings = keyPathList;
        }
    }
}

- (NSArray *)nestedAttributeMappings
{
    [self cacheMappingsIfNeeded];
    return _nestedAttributeMappings;
}

- (NSArray *)simpleAttributeMappings
{
    [self cacheMappingsIfNeeded];
    return _simpleAttributeMappings;
}

- (NSArray *)keyPathAttributeMappings
{
    [self cacheMappingsIfNeeded];
    return _keyPathAttributeMappings;
}

- (NSArray *)relationshipMappings
{
    [self cacheMappingsIfNeeded];
    return _relationshipMappings;
}

- (BOOL)transformValue:(id)inputValue toValue:(__autoreleasing id *)outputValue withPropertyMapping:(RKPropertyMapping *)propertyMapping error:(NSError *__autoreleasing *)error
{
    if (! inputValue) {
        *outputValue = nil;
        // We only want to consider the transformation successful and assign nil if the mapping calls for it
        return propertyMapping.objectMapping.assignsDefaultValueForMissingAttributes;
    }
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

- (BOOL)applyAttributeMapping:(RKAttributeMapping *)attributeMapping withValue:(id)value
{
    id transformedValue = nil;
    NSError *error = nil;
    if (! [self transformValue:value toValue:&transformedValue withPropertyMapping:attributeMapping error:&error]) return NO;

    NSString *destinationKeyPath = attributeMapping.destinationKeyPath;
    id destinationObject = self.destinationObject;
    id delegate = self.delegate;

    if ([delegate respondsToSelector:@selector(mappingOperation:didFindValue:forKeyPath:mapping:)]) {
        [delegate mappingOperation:self didFindValue:value forKeyPath:attributeMapping.sourceKeyPath mapping:attributeMapping];
    }
    RKLogTrace(@"Mapping attribute value keyPath '%@' to '%@'", attributeMapping.sourceKeyPath, destinationKeyPath);
    
    // If we have a nil value for a primitive property, we need to coerce it into a KVC usable value or bail out
    if (transformedValue == nil && RKPropertyInspectorIsPropertyAtKeyPathOfObjectPrimitive(destinationKeyPath, destinationObject)) {
        RKLogDebug(@"Detected `nil` value transformation for primitive property at keyPath '%@'", destinationKeyPath);
        transformedValue = RKPrimitiveValueForNilValueOfClass([self.objectMapping classForKeyPath:destinationKeyPath]);
        if (! transformedValue) {
            RKLogTrace(@"Skipped mapping of attribute value from keyPath '%@ to keyPath '%@' -- Unable to transform `nil` into primitive value representation", attributeMapping.sourceKeyPath, destinationKeyPath);
            return NO;
        }
    }

    RKSetIntermediateDictionaryValuesOnObjectForKeyPath(destinationObject, destinationKeyPath);
    
    // Ensure that the value is different
    if ([self shouldSetValue:&transformedValue forKeyPath:destinationKeyPath usingMapping:attributeMapping]) {
        RKLogTrace(@"Mapped attribute value from keyPath '%@' to '%@'. Value: %@", attributeMapping.sourceKeyPath, destinationKeyPath, transformedValue);
        
        if (destinationKeyPath) {
            [destinationObject setValue:transformedValue forKeyPath:destinationKeyPath];
        } else {
            if ([destinationObject isKindOfClass:[NSMutableDictionary class]] && [transformedValue isKindOfClass:[NSDictionary class]]) {
                [destinationObject setDictionary:transformedValue];
            } else {
                [NSException raise:NSInvalidArgumentException format:@"Unable to set value for destination object of type '%@': Can only directly set destination object for `NSMutableDictionary` targets. (transformedValue=%@)", [destinationObject class], transformedValue];
            }
        }
        if ([delegate respondsToSelector:@selector(mappingOperation:didSetValue:forKeyPath:usingMapping:)]) {
            [delegate mappingOperation:self didSetValue:transformedValue forKeyPath:destinationKeyPath usingMapping:attributeMapping];
        }
    } else {
        RKLogTrace(@"Skipped mapping of attribute value from keyPath '%@ to keyPath '%@' -- value is unchanged (%@)", attributeMapping.sourceKeyPath, destinationKeyPath, transformedValue);
        if ([delegate respondsToSelector:@selector(mappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
            [delegate mappingOperation:self didNotSetUnchangedValue:transformedValue forKeyPath:destinationKeyPath usingMapping:attributeMapping];
        }
    }
    if (_collectsMappingInfo) {
        [self.mappingInfo addPropertyMapping:attributeMapping];
    }
    return YES;
}

// Return YES if we mapped any attributes
- (BOOL)applyAttributeMappings:(NSArray *)attributeMappings
{
    // If we have a nesting substitution value, we have already succeeded
    BOOL appliedMappings = (self.nestedAttributeSubstitutionKey != nil);

    if (!self.objectMapping.performsKeyValueValidation) {
        RKLogDebug(@"Key-value validation is disabled for mapping, skipping...");
    }

    id sourceObject = self.sourceObject;

    for (RKAttributeMapping *attributeMapping in attributeMappings) {
        if ([self isCancelled]) return NO;

        NSString *sourceKeyPath = attributeMapping.sourceKeyPath;
        NSString *destinationKeyPath = attributeMapping.destinationKeyPath;
        if ([sourceKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName] || [destinationKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName]) {
            RKLogTrace(@"Skipping attribute mapping for special keyPath '%@'", sourceKeyPath);
            continue;
        }

        id value = (sourceKeyPath == nil) ? [sourceObject valueForKey:@"self"] : [sourceObject valueForKeyPath:sourceKeyPath];
        if ([self applyAttributeMapping:attributeMapping withValue:value]) {
            appliedMappings = YES;
        } else {
            id delegate = self.delegate;
            RKObjectMapping *objectMapping = self.objectMapping;

            if ([delegate respondsToSelector:@selector(mappingOperation:didNotFindValueForKeyPath:mapping:)]) {
                [delegate mappingOperation:self didNotFindValueForKeyPath:sourceKeyPath mapping:attributeMapping];
            }
            RKLogTrace(@"Did not find mappable attribute value keyPath '%@'", sourceKeyPath);

            // Optionally set the default value for missing values
            if (objectMapping.assignsDefaultValueForMissingAttributes) {
                [self.destinationObject setValue:[objectMapping defaultValueForAttribute:destinationKeyPath]
                                      forKeyPath:destinationKeyPath];
                RKLogTrace(@"Setting nil for missing attribute value at keyPath '%@'", sourceKeyPath);
            }
        }

        // Fail out if an error has occurred
        if (self.error) break;
    }

    return appliedMappings;
}

- (BOOL)mapNestedObject:(id)anObject toObject:(id)anotherObject parent:(id)parentSourceObject withRelationshipMapping:(RKRelationshipMapping *)relationshipMapping metadataList:(NSArray *)metadataList
{
    NSAssert(anObject, @"Cannot map nested object without a nested source object");
    NSAssert(anotherObject, @"Cannot map nested object without a destination object");
    NSAssert(relationshipMapping, @"Cannot map a nested object relationship without a relationship mapping");

    RKLogTrace(@"Performing nested object mapping using mapping %@ for data: %@", relationshipMapping, anObject);
    RKMappingOperation *subOperation = [[RKMappingOperation alloc] initWithSourceObject:anObject destinationObject:anotherObject mapping:relationshipMapping.mapping metadataList:metadataList];
    subOperation.dataSource = self.dataSource;
    subOperation.delegate = self.delegate;
    subOperation.parentSourceObject = parentSourceObject;
    subOperation.rootSourceObject = self.rootSourceObject;
    subOperation.newDestinationObject = YES;
    [subOperation start];
    
    if (subOperation.error) {
        RKLogWarning(@"WARNING: Failed mapping nested object: %@", [subOperation.error localizedDescription]);
    } else if (self.collectsMappingInfo) {
        RKMappingInfo *mappingInfo = self.mappingInfo;
        RKMappingInfo *subMappingInfo = subOperation.mappingInfo;
        [mappingInfo addPropertyMapping:relationshipMapping];
        if (subMappingInfo) {
            [mappingInfo addMappingInfo:subMappingInfo forRelationshipMapping:relationshipMapping];
        }
    }

    return YES;
}

- (BOOL)applyReplaceAssignmentPolicyForRelationshipMapping:(RKRelationshipMapping *)relationshipMapping
{
    if (relationshipMapping.assignmentPolicy == RKReplaceAssignmentPolicy) {
        id dataSource = self.dataSource;
        if ([dataSource respondsToSelector:@selector(mappingOperation:deleteExistingValueOfRelationshipWithMapping:error:)]) {
            NSError *error = nil;
            BOOL success = [dataSource mappingOperation:self deleteExistingValueOfRelationshipWithMapping:relationshipMapping error:&error];
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
    static dispatch_once_t onceToken;
    static NSDictionary *noIndexMetadata;
    dispatch_once(&onceToken, ^{
        noIndexMetadata = @{ @"mapping" : @{ @"collectionIndex" : [NSNull null] } };
    });

    // One to one relationship
    NSString *destinationKeyPath = relationshipMapping.destinationKeyPath;
    RKLogDebug(@"Mapping one to one relationship value at keyPath '%@' to '%@'", relationshipMapping.sourceKeyPath, destinationKeyPath);
    
    if (relationshipMapping.assignmentPolicy == RKUnionAssignmentPolicy) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Invalid assignment policy: cannot union a one-to-one relationship." };
        self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorInvalidAssignmentPolicy userInfo:userInfo];
        return NO;
    }
    
    // Remove existing destination entity before mapping the new one
    if (relationshipMapping.assignmentPolicy == RKAssignmentPolicyReplace && ![self applyReplaceAssignmentPolicyForRelationshipMapping:relationshipMapping]) {
        return NO;
    }

    id parentSourceObject = [self parentObjectForRelationshipMapping:relationshipMapping];
    id destinationObject = [self destinationObjectForMappingRepresentation:value parentRepresentation:parentSourceObject withMapping:relationshipMapping.mapping inRelationship:relationshipMapping];
    if (! destinationObject) {
        RKLogDebug(@"Mapping %@ declined mapping for representation %@: returned `nil` destination object.", relationshipMapping.mapping, destinationObject);
        return NO;
    }

    NSArray *subOperationMetadata = RKInsertInMetadataList(self.metadataList, noIndexMetadata, nil);
    [self mapNestedObject:value toObject:destinationObject parent:parentSourceObject withRelationshipMapping:relationshipMapping metadataList:subOperationMetadata];

    // If the relationship has changed, set it
    if ([self shouldSetValue:&destinationObject forKeyPath:destinationKeyPath usingMapping:relationshipMapping]) {
        RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, destinationKeyPath, destinationObject);
        [self.destinationObject setValue:destinationObject forKeyPath:destinationKeyPath];
    } else {
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
            [self.delegate mappingOperation:self didNotSetUnchangedValue:destinationObject forKeyPath:destinationKeyPath usingMapping:relationshipMapping];
        }
    }

    return YES;
}

- (BOOL)mapCoreDataToManyRelationshipValue:(id)valueForRelationship withMapping:(RKRelationshipMapping *)relationshipMapping
{
    id destinationObject = self.destinationObject;
    if (! RKIsManagedObject(destinationObject)) return NO;

    RKLogTrace(@"Mapping a to-many relationship for an `NSManagedObject`. About to apply value via mutable[Set|Array]ValueForKey");
    if ([valueForRelationship isKindOfClass:[NSSet class]]) {
        RKLogTrace(@"Mapped `NSSet` relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, valueForRelationship);
        NSMutableSet *destinationSet = [destinationObject mutableSetValueForKeyPath:relationshipMapping.destinationKeyPath];
        [destinationSet setSet:valueForRelationship];
    } else if ([valueForRelationship isKindOfClass:[NSArray class]]) {
        RKLogTrace(@"Mapped `NSArray` relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, valueForRelationship);
        NSMutableArray *destinationArray = [destinationObject mutableArrayValueForKeyPath:relationshipMapping.destinationKeyPath];
        [destinationArray setArray:valueForRelationship];
    } else if ([valueForRelationship isKindOfClass:[NSOrderedSet class]]) {
        RKLogTrace(@"Mapped `NSOrderedSet` relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, valueForRelationship);
        [destinationObject setValue:valueForRelationship forKeyPath:relationshipMapping.destinationKeyPath];
    }

    return YES;
}

- (BOOL)mapOneToManyRelationshipWithValue:(id)value mapping:(RKRelationshipMapping *)relationshipMapping
{
    NSString *destinationKeyPath = relationshipMapping.destinationKeyPath;
    
    // One to many relationship
    RKLogDebug(@"Mapping one to many relationship value at keyPath '%@' to '%@'", relationshipMapping.sourceKeyPath, destinationKeyPath);

    NSMutableArray *relationshipCollection = [NSMutableArray arrayWithCapacity:[value count]];
    if (RKObjectIsCollectionOfCollections(value)) {
        RKLogWarning(@"WARNING: Detected a relationship mapping for a collection containing another collection. This is probably not what you want. Consider using a KVC collection operator (such as @unionOfArrays) to flatten your mappable collection.");
        RKLogWarning(@"Key path '%@' yielded collection containing another collection rather than a collection of objects", relationshipMapping.sourceKeyPath);
        RKLogDebug(@"(Value at key path '%@': %@)", relationshipMapping.sourceKeyPath, value);
    }
    
    if (relationshipMapping.assignmentPolicy == RKUnionAssignmentPolicy) {
        RKLogDebug(@"Mapping relationship with union assignment policy: constructing combined relationship value.");
        id existingObjects = [self.destinationObject valueForKeyPath:destinationKeyPath];
        if (existingObjects) {
            NSArray *existingObjectsArray = nil;
            NSError *error = nil;
            [[RKValueTransformer defaultValueTransformer] transformValue:existingObjects toValue:&existingObjectsArray ofClass:[NSArray class] error:&error];
            [relationshipCollection addObjectsFromArray:existingObjectsArray];
        }
    }
    else if (relationshipMapping.assignmentPolicy == RKReplaceAssignmentPolicy) {
        if (! [self applyReplaceAssignmentPolicyForRelationshipMapping:relationshipMapping]) {
            return NO;
        }
    }

    RKMapping *relationshipDestinationMapping = relationshipMapping.mapping;
    id parentSourceObject = [self parentObjectForRelationshipMapping:relationshipMapping];
    RKMappingIndexMetadata *indexMetadata = [RKMappingIndexMetadata new];
    NSArray *subOperationMetadata = RKInsertInMetadataList(self.metadataList, indexMetadata, nil);
    [value enumerateObjectsUsingBlock:^(id nestedObject, NSUInteger collectionIndex, BOOL *stop) {
        id mappableObject = [self destinationObjectForMappingRepresentation:nestedObject parentRepresentation:parentSourceObject withMapping:relationshipDestinationMapping inRelationship:relationshipMapping];
        if (mappableObject) {
            indexMetadata.collectionIndex = collectionIndex;
            if ([self mapNestedObject:nestedObject toObject:mappableObject parent:parentSourceObject withRelationshipMapping:relationshipMapping metadataList:subOperationMetadata]) {
                [relationshipCollection addObject:mappableObject];
            }
        } else {
            RKLogDebug(@"Mapping %@ declined mapping for representation %@: returned `nil` destination object.", relationshipDestinationMapping, nestedObject);
        }
    }];

    id valueForRelationship = nil;
    NSError *error = nil;
    if (! [self transformValue:relationshipCollection toValue:&valueForRelationship withPropertyMapping:relationshipMapping error:&error]) return NO;

    // If the relationship has changed, set it
    if ([self shouldSetValue:&valueForRelationship forKeyPath:destinationKeyPath usingMapping:relationshipMapping]) {
        if (! [self mapCoreDataToManyRelationshipValue:valueForRelationship withMapping:relationshipMapping]) {
            RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, destinationKeyPath, valueForRelationship);
            [self.destinationObject setValue:valueForRelationship forKeyPath:destinationKeyPath];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
            [self.delegate mappingOperation:self didNotSetUnchangedValue:valueForRelationship forKeyPath:destinationKeyPath usingMapping:relationshipMapping];
        }

        return NO;
    }

    return YES;
}

- (BOOL)applyRelationshipMappings
{
    NSAssert(self.dataSource, @"Cannot perform relationship mapping without a data source");
    NSUInteger mappingsApplied = 0;
    RKObjectMapping *parentObjectMapping = self.objectMapping;
    id sourceObject = self.sourceObject;
    id destinationObject = self.destinationObject;
    id delegate = self.delegate;

    for (RKRelationshipMapping *relationshipMapping in [self relationshipMappings]) {
        if ([self isCancelled]) return NO;
        
        NSString *sourceKeyPath = relationshipMapping.sourceKeyPath;
        NSString *destinationKeyPath = relationshipMapping.destinationKeyPath;
        id value = nil;

        if (sourceKeyPath) {
            value = [sourceObject valueForKeyPath:sourceKeyPath];
        } else {
            // The nil source keyPath indicates that we want to map directly from the parent representation
            value = sourceObject;
            RKMapping *destinationMapping = relationshipMapping.mapping;
            RKObjectMapping *objectMapping = nil;
            
            if ([destinationMapping isKindOfClass:[RKObjectMapping class]]) {
                objectMapping = (RKObjectMapping *)destinationMapping;
            } else if ([destinationMapping isKindOfClass:[RKDynamicMapping class]]) {
                objectMapping = [(RKDynamicMapping *)destinationMapping objectMappingForRepresentation:value];
            }
            
            if (! objectMapping) continue; // Mapping declined
            if (! RKObjectContainsValueForMappings(value, objectMapping.propertyMappings)) {
                continue;
            }
        }

        // Track that we applied this mapping
        mappingsApplied++;

        if (value == nil) {
            RKLogDebug(@"Did not find mappable relationship value keyPath '%@'", sourceKeyPath);
            if (! parentObjectMapping.assignsNilForMissingRelationships) continue;
        }
        
        if (value == [NSNull null]) {
            RKLogDebug(@"Found null value at keyPath '%@'", sourceKeyPath);
            value = nil;
        }

        // nil out the property if necessary
        if (value == nil) {
            Class relationshipClass = [parentObjectMapping classForKeyPath:destinationKeyPath];
            BOOL mappingToCollection = RKClassIsCollection(relationshipClass);
            RKAssignmentPolicy assignmentPolicy = relationshipMapping.assignmentPolicy;
            if (assignmentPolicy == RKUnionAssignmentPolicy && mappingToCollection) {
                // Unioning `nil` with the existing value is functionally equivalent to doing nothing, so just continue
                continue;
            } else if (assignmentPolicy == RKUnionAssignmentPolicy) {
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Invalid assignment policy: cannot union a one-to-one relationship." };
                self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorInvalidAssignmentPolicy userInfo:userInfo];
                continue;
            } else if (assignmentPolicy == RKReplaceAssignmentPolicy) {
                if (! [self applyReplaceAssignmentPolicyForRelationshipMapping:relationshipMapping]) {
                    continue;
                }
            }

            if ([self shouldSetValue:&value forKeyPath:destinationKeyPath usingMapping:relationshipMapping]) {
                RKLogTrace(@"Setting nil for relationship value at keyPath '%@'", sourceKeyPath);
                [destinationObject setValue:value forKeyPath:destinationKeyPath];
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
                    NSDictionary *dictionaryToMap = @{key: [value valueForKey:key]};
                    [(NSMutableArray *)objectsToMap addObject:dictionaryToMap];
                }
                value = objectsToMap;
            } else {
                RKLogWarning(@"Collection mapping forced but mappable objects is of type '%@' rather than NSDictionary", NSStringFromClass([value class]));
            }
        }

        // Handle case where incoming content is a single object, but we want a collection
        Class relationshipClass = [parentObjectMapping classForKeyPath:destinationKeyPath];
        BOOL mappingToCollection = RKClassIsCollection(relationshipClass);
        BOOL objectIsCollection = RKObjectIsCollection(value);
        if (mappingToCollection && !objectIsCollection) {
            RKLogDebug(@"Asked to map a single object into a collection relationship. Transforming to an instance of: %@", NSStringFromClass(relationshipClass));
            if ([relationshipClass isSubclassOfClass:[NSArray class]]) {
                value = [relationshipClass arrayWithObject:value];
                objectIsCollection = YES;
            } else if ([relationshipClass isSubclassOfClass:[NSSet class]]) {
                value = [relationshipClass setWithObject:value];
                objectIsCollection = YES;
            } else if ([relationshipClass isSubclassOfClass:[NSOrderedSet class]]) {
                value = [relationshipClass orderedSetWithObject:value];
                objectIsCollection = YES;
            } else {
                RKLogWarning(@"Failed to transform single object");
            }
        }

        BOOL setValueForRelationship;
        if (objectIsCollection) {
            setValueForRelationship = [self mapOneToManyRelationshipWithValue:value mapping:relationshipMapping];
        } else {
            setValueForRelationship = [self mapOneToOneRelationshipWithValue:value mapping:relationshipMapping];
        }

        if (! setValueForRelationship) continue;

        // Notify the delegate
        if ([delegate respondsToSelector:@selector(mappingOperation:didSetValue:forKeyPath:usingMapping:)]) {
            id setValue = [destinationObject valueForKeyPath:destinationKeyPath];
            [delegate mappingOperation:self didSetValue:setValue forKeyPath:destinationKeyPath usingMapping:relationshipMapping];
        }

        // Fail out if a validation error has occurred
        if (self.error) break;
    }

    return mappingsApplied > 0;
}

- (void)applyNestedMappings
{
    RKObjectMapping *objectMapping = self.objectMapping;
    RKAttributeMapping *attributeMapping = [objectMapping mappingForSourceKeyPath:RKObjectMappingNestingAttributeKeyName];
    if (attributeMapping) {
        RKLogDebug(@"Found nested mapping definition to attribute '%@'", attributeMapping.destinationKeyPath);
        id attributeValue = [[self.sourceObject allKeys] lastObject];
        if (attributeValue) {
            RKLogDebug(@"Found nesting value of '%@' for attribute '%@'", attributeValue, attributeMapping.destinationKeyPath);
            self.nestedAttributeSubstitutionKey = attributeMapping.destinationKeyPath;
            self.nestedAttributeSubstitutionValue = attributeValue;
            [self applyAttributeMapping:attributeMapping withValue:attributeValue];
        } else {
            RKLogWarning(@"Unable to find nesting value for attribute '%@'", attributeMapping.destinationKeyPath);
        }
    }
    
    // Serialization
    attributeMapping = [objectMapping mappingForDestinationKeyPath:RKObjectMappingNestingAttributeKeyName];
    if (attributeMapping) {
        RKLogDebug(@"Found nested mapping definition to attribute '%@'", attributeMapping.destinationKeyPath);
        id attributeValue = [self.sourceObject valueForKeyPath:attributeMapping.sourceKeyPath];
        if (attributeValue) {
            RKLogDebug(@"Found nesting value of '%@' for attribute '%@'", attributeValue, attributeMapping.sourceKeyPath);
            self.nestedAttributeSubstitutionKey = attributeMapping.sourceKeyPath;
            self.nestedAttributeSubstitutionValue = attributeValue;
        } else {
            RKLogWarning(@"Unable to find nesting value for attribute '%@'", attributeMapping.destinationKeyPath);
        }
    }
}

- (void)cancel
{
    self.cancelled = YES;
    RKLogDebug(@"Mapping operation cancelled: %@", self);
}

- (void)start
{
    [self main];
}

- (void)main
{
    if ([self isCancelled]) return;

    // Handle metadata
    id parentSourceObject = self.parentSourceObject;
    id sourceObject = [[RKMappingSourceObject alloc] initWithObject:self.sourceObject parentObject:parentSourceObject rootObject:self.rootSourceObject metadata:self.metadataList];
    self.sourceObject = sourceObject;

    RKLogDebug(@"Starting mapping operation...");
    RKLogTrace(@"Performing mapping operation: %@", self);
    
    id dataSource = self.dataSource;
    id delegate = self.delegate;
    RKMapping *mapping = self.mapping;
    RKObjectMapping *objectMapping;

    if (! self.destinationObject) {
        self.destinationObject = [self destinationObjectForMappingRepresentation:sourceObject parentRepresentation:parentSourceObject withMapping:mapping inRelationship:nil];
        if (! self.destinationObject) {
            RKLogDebug(@"Mapping operation failed: Given nil destination object and unable to instantiate a destination object for mapping.");
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Cannot perform a mapping operation with a nil destination object." };
            self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorNilDestinationObject userInfo:userInfo];
            return;
        }
        self.newDestinationObject = YES;
    }
    
    self.collectsMappingInfo = (![dataSource respondsToSelector:@selector(mappingOperationShouldCollectMappingInfo:)] ||
                                [dataSource mappingOperationShouldCollectMappingInfo:self]);

    self.shouldSetUnchangedValues = ([self.dataSource respondsToSelector:@selector(mappingOperationShouldSetUnchangedValues:)] &&
                                     [self.dataSource mappingOperationShouldSetUnchangedValues:self]);
    
    // Determine the concrete mapping if we were initialized with a dynamic mapping
    if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
        self.objectMapping = objectMapping = [(RKDynamicMapping *)mapping objectMappingForRepresentation:sourceObject];
        if (! objectMapping) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"A dynamic mapping failed to return a concrete object mapping matching the representation being mapped." };
            self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorUnableToDetermineMapping userInfo:userInfo];
            return;
        }
        RKLogDebug(@"RKObjectMappingOperation was initialized with a dynamic mapping. Determined concrete mapping = %@", objectMapping);

        if ([delegate respondsToSelector:@selector(mappingOperation:didSelectObjectMapping:forDynamicMapping:)]) {
            [delegate mappingOperation:self didSelectObjectMapping:objectMapping forDynamicMapping:(RKDynamicMapping *)mapping];
        }
        if (self.collectsMappingInfo) {
            self.mappingInfo = [[RKMappingInfo alloc] initWithObjectMapping:objectMapping dynamicMapping:(RKDynamicMapping *)mapping];
        }
    } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
        self.objectMapping = objectMapping = (RKObjectMapping *)mapping;
        if (self.collectsMappingInfo) {
            self.mappingInfo = [[RKMappingInfo alloc] initWithObjectMapping:objectMapping dynamicMapping:nil];
        }
    }
    
    BOOL canSkipMapping = [dataSource respondsToSelector:@selector(mappingOperationShouldSkipPropertyMapping:)] && [dataSource mappingOperationShouldSkipPropertyMapping:self];
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
            if ([dataSource respondsToSelector:@selector(commitChangesForMappingOperation:error:)]) {
                NSError *error = nil;
                BOOL success = [dataSource commitChangesForMappingOperation:self error:&error];
                if (! success) {
                    self.error = error;
                }
            }
        }
    }

    if (self.error) {
        if ([delegate respondsToSelector:@selector(mappingOperation:didFailWithError:)]) {
            [delegate mappingOperation:self didFailWithError:self.error];
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
