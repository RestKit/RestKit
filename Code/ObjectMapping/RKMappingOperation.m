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

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitObjectMapping

extern NSString * const RKObjectMappingNestingAttributeKeyName;

// Defined in RKObjectMapping.h
NSDate *RKDateFromStringWithFormatters(NSString *dateString, NSArray *formatters);

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

id RKTransformedValueWithClass(id value, Class destinationType, NSValueTransformer *dateToStringValueTransformer);
id RKTransformedValueWithClass(id value, Class destinationType, NSValueTransformer *dateToStringValueTransformer)
{
    Class sourceType = [value class];
    
    if ([value isKindOfClass:destinationType]) {
        // No transformation necessary
        return value;
    } else if ([sourceType isSubclassOfClass:[NSString class]] && [destinationType isSubclassOfClass:[NSDate class]]) {
        // String -> Date
        return [dateToStringValueTransformer transformedValue:value];
    } else if ([destinationType isSubclassOfClass:[NSString class]] && [value isKindOfClass:[NSDate class]]) {
        // NSDate -> NSString
        // Transform using the preferred date formatter
        return [dateToStringValueTransformer reverseTransformedValue:value];
    } else if ([destinationType isSubclassOfClass:[NSData class]]) {
        return [NSKeyedArchiver archivedDataWithRootObject:value];
    } else if ([sourceType isSubclassOfClass:[NSString class]]) {
        if ([destinationType isSubclassOfClass:[NSURL class]]) {
            // String -> URL
            return [NSURL URLWithString:(NSString *)value];
        } else if ([destinationType isSubclassOfClass:[NSDecimalNumber class]]) {
            // String -> Decimal Number
            return [NSDecimalNumber decimalNumberWithString:(NSString *)value];
        } else if ([destinationType isSubclassOfClass:[NSNumber class]]) {
            // String -> Number
            NSString *lowercasedString = [(NSString *)value lowercaseString];
            NSSet *trueStrings = [NSSet setWithObjects:@"true", @"t", @"yes", nil];
            NSSet *booleanStrings = [trueStrings setByAddingObjectsFromSet:[NSSet setWithObjects:@"false", @"f", @"no", nil]];
            if ([booleanStrings containsObject:lowercasedString]) {
                // Handle booleans encoded as Strings
                return [NSNumber numberWithBool:[trueStrings containsObject:lowercasedString]];
            } else {
                return [NSNumber numberWithDouble:[(NSString *)value doubleValue]];
            }
        }
    } else if ([value isEqual:[NSNull null]]) {
        // Transform NSNull -> nil for simplicity
        return nil;
    } else if ([sourceType isSubclassOfClass:[NSSet class]]) {
        // Set -> Array
        if ([destinationType isSubclassOfClass:[NSArray class]]) {
            return [(NSSet *)value allObjects];
        }
    } else if ([sourceType isSubclassOfClass:[NSOrderedSet class]]) {
        // OrderedSet -> Array
        if ([destinationType isSubclassOfClass:[NSArray class]]) {
            return [value array];
        }
    } else if ([sourceType isSubclassOfClass:[NSArray class]]) {
        // Array -> Set
        if ([destinationType isSubclassOfClass:[NSSet class]]) {
            return [NSSet setWithArray:value];
        }
        // Array -> OrderedSet
        if ([destinationType isSubclassOfClass:[NSOrderedSet class]]) {
            return [[NSOrderedSet class] orderedSetWithArray:value];
        }
    } else if ([sourceType isSubclassOfClass:[NSNumber class]] && [destinationType isSubclassOfClass:[NSDate class]]) {
        // Number -> Date
        if ([destinationType isSubclassOfClass:[NSDate class]]) {
            return [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)value intValue]];
        } else if ([sourceType isSubclassOfClass:NSClassFromString(@"__NSCFBoolean")] && [destinationType isSubclassOfClass:[NSString class]]) {
            return ([value boolValue] ? @"true" : @"false");
        }
        return [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)value doubleValue]];
    } else if ([sourceType isSubclassOfClass:[NSNumber class]] && [destinationType isSubclassOfClass:[NSDecimalNumber class]]) {
        // Number -> Decimal Number
        return [NSDecimalNumber decimalNumberWithDecimal:[value decimalValue]];
    } else if ( ([sourceType isSubclassOfClass:NSClassFromString(@"__NSCFBoolean")] ||
                 [sourceType isSubclassOfClass:NSClassFromString(@"NSCFBoolean")] ) &&
               [destinationType isSubclassOfClass:[NSString class]]) {
        return ([value boolValue] ? @"true" : @"false");
        if ([destinationType isSubclassOfClass:[NSDate class]]) {
            return [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)value intValue]];
        } else if (([sourceType isSubclassOfClass:NSClassFromString(@"__NSCFBoolean")] || [sourceType isSubclassOfClass:NSClassFromString(@"NSCFBoolean")]) && [destinationType isSubclassOfClass:[NSString class]]) {
            return ([value boolValue] ? @"true" : @"false");
        }
    } else if ([destinationType isSubclassOfClass:[NSString class]] && [value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    
    return nil;
}

// Applies
// Key comes from: [[_nestedAttributeSubstitution allKeys] lastObject]] AND [[_nestedAttributeSubstitution allValues] lastObject];
NSArray *RKApplyNestingAttributeValueToMappings(NSString *attributeName, id value, NSArray *propertyMappings);
NSArray *RKApplyNestingAttributeValueToMappings(NSString *attributeName, id value, NSArray *propertyMappings)
{
    if (!attributeName) return propertyMappings;
        
    NSString *searchString = [NSString stringWithFormat:@"(%@)", attributeName];
    NSString *replacementString = [NSString stringWithFormat:@"%@", value];
    NSMutableArray *nestedMappings = [NSMutableArray arrayWithCapacity:[propertyMappings count]];
    for (RKPropertyMapping *propertyMapping in propertyMappings) {
        NSString *sourceKeyPath = [propertyMapping.sourceKeyPath stringByReplacingOccurrencesOfString:searchString withString:replacementString];
        NSString *destinationKeyPath = [propertyMapping.destinationKeyPath stringByReplacingOccurrencesOfString:searchString withString:replacementString];
        RKPropertyMapping *nestedMapping = nil;
        if ([propertyMapping isKindOfClass:[RKAttributeMapping class]]) {
            nestedMapping = [RKAttributeMapping attributeMappingFromKeyPath:sourceKeyPath toKeyPath:destinationKeyPath];
        } else if ([propertyMapping isKindOfClass:[RKRelationshipMapping class]]) {
            nestedMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:sourceKeyPath
                                                                        toKeyPath:destinationKeyPath
                                                                      withMapping:[(RKRelationshipMapping *)propertyMapping mapping]];
        }
        [nestedMappings addObject:nestedMapping];
    }
    
    return nestedMappings;
}

@interface RKMappingOperation ()
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, strong, readwrite) id sourceObject;
@property (nonatomic, strong, readwrite) id destinationObject;
@property (nonatomic, strong) NSDictionary *nestedAttributeSubstitution;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) RKObjectMapping *objectMapping; // The concrete mapping
@end

@implementation RKMappingOperation

- (id)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject mapping:(RKMapping *)objectOrDynamicMapping
{
    NSAssert(sourceObject != nil, @"Cannot perform a mapping operation without a sourceObject object");
    NSAssert(objectOrDynamicMapping != nil, @"Cannot perform a mapping operation without a mapping");

    self = [super init];
    if (self) {
        self.sourceObject = sourceObject;
        self.destinationObject = destinationObject;
        self.mapping = objectOrDynamicMapping;
    }

    return self;
}

- (id)destinationObjectForMappingRepresentation:(id)representation withMapping:(RKMapping *)mapping
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
    
    return [self.dataSource mappingOperation:self targetObjectForRepresentation:representation withMapping:concreteMapping];
}

- (NSDate *)parseDateFromString:(NSString *)string
{
    RKLogTrace(@"Transforming string value '%@' to NSDate...", string);
    return RKDateFromStringWithFormatters(string, self.objectMapping.dateFormatters);
}

- (id)transformValue:(id)value atKeyPath:(NSString *)keyPath toType:(Class)destinationType
{
    RKLogTrace(@"Found transformable value at keyPath '%@'. Transforming from type '%@' to '%@'", keyPath, NSStringFromClass([value class]), NSStringFromClass(destinationType));
    RKDateToStringValueTransformer *transformer = [[RKDateToStringValueTransformer alloc] initWithDateToStringFormatter:self.objectMapping.preferredDateFormatter stringToDateFormatters:self.objectMapping.dateFormatters];
    id transformedValue = RKTransformedValueWithClass(value, destinationType, transformer);
    if (transformedValue != value) return transformedValue;
    
    RKLogWarning(@"Failed transformation of value at keyPath '%@'. No strategy for transforming from '%@' to '%@'", keyPath, NSStringFromClass([value class]), NSStringFromClass(destinationType));

    return nil;
}

- (BOOL)isValue:(id)sourceValue equalToValue:(id)destinationValue
{
    return RKObjectIsEqualToObject(sourceValue, destinationValue);
}

- (BOOL)validateValue:(id *)value atKeyPath:(NSString *)keyPath
{
    BOOL success = YES;

    if (self.objectMapping.performKeyValueValidation && [self.destinationObject respondsToSelector:@selector(validateValue:forKeyPath:error:)]) {
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

- (BOOL)shouldSetValue:(id *)value atKeyPath:(NSString *)keyPath
{
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
    if (*value == [NSNull null]) {
        RKLogWarning(@"Coercing NSNull value to nil in shouldSetValue:atKeyPath: -- should be fixed.");
        *value = nil;
    }

    if (nil == currentValue && nil == *value) {
        // Both are nil
        return NO;
    } else if (nil == *value || nil == currentValue) {
        // One is nil and the other is not
        return [self validateValue:value atKeyPath:keyPath];
    }

    if (! [self isValue:*value equalToValue:currentValue]) {
        // Validate value for key
        return [self validateValue:value atKeyPath:keyPath];
    }
    return NO;
}

- (NSArray *)applyNestingToMappings:(NSArray *)mappings
{
    if (_nestedAttributeSubstitution) {
        return RKApplyNestingAttributeValueToMappings([[_nestedAttributeSubstitution allKeys] lastObject], [[_nestedAttributeSubstitution allValues] lastObject], mappings);
    }

    return mappings;
}

- (NSArray *)simpleAttributeMappings
{
    NSMutableArray *mappings = [NSMutableArray array];
    for (RKAttributeMapping *mapping in [self applyNestingToMappings:self.objectMapping.attributeMappings]) {
        if ([mapping.sourceKeyPath rangeOfString:@"."].location == NSNotFound) {
            [mappings addObject:mapping];
        }
    }

    return mappings;
}

- (NSArray *)keyPathAttributeMappings
{
    NSMutableArray *mappings = [NSMutableArray array];
    for (RKAttributeMapping *mapping in [self applyNestingToMappings:self.objectMapping.attributeMappings]) {
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

- (void)applyAttributeMapping:(RKAttributeMapping *)attributeMapping withValue:(id)value
{
    if ([self.delegate respondsToSelector:@selector(mappingOperation:didFindValue:forKeyPath:mapping:)]) {
        [self.delegate mappingOperation:self didFindValue:value forKeyPath:attributeMapping.sourceKeyPath mapping:attributeMapping];
    }
    RKLogTrace(@"Mapping attribute value keyPath '%@' to '%@'", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath);

    // Inspect the property type to handle any value transformations
    Class type = [self.objectMapping classForKeyPath:attributeMapping.destinationKeyPath];
    if (type && NO == [[value class] isSubclassOfClass:type]) {
        value = [self transformValue:value atKeyPath:attributeMapping.sourceKeyPath toType:type];
    }

    RKSetIntermediateDictionaryValuesOnObjectForKeyPath(self.destinationObject, attributeMapping.destinationKeyPath);
    
    // Ensure that the value is different
    if ([self shouldSetValue:&value atKeyPath:attributeMapping.destinationKeyPath]) {
        RKLogTrace(@"Mapped attribute value from keyPath '%@' to '%@'. Value: %@", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath, value);
        
        [self.destinationObject setValue:value forKeyPath:attributeMapping.destinationKeyPath];
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didSetValue:forKeyPath:usingMapping:)]) {
            [self.delegate mappingOperation:self didSetValue:value forKeyPath:attributeMapping.destinationKeyPath usingMapping:attributeMapping];
        }
    } else {
        RKLogTrace(@"Skipped mapping of attribute value from keyPath '%@ to keyPath '%@' -- value is unchanged (%@)", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath, value);
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
            [self.delegate mappingOperation:self didNotSetUnchangedValue:value forKeyPath:attributeMapping.destinationKeyPath usingMapping:attributeMapping];
        }
    }
}

// Return YES if we mapped any attributes
- (BOOL)applyAttributeMappings:(NSArray *)attributeMappings
{
    // If we have a nesting substitution value, we have already succeeded
    BOOL appliedMappings = (_nestedAttributeSubstitution != nil);

    if (!self.objectMapping.performKeyValueValidation) {
        RKLogDebug(@"Key-value validation is disabled for mapping, skipping...");
    }

    for (RKAttributeMapping *attributeMapping in attributeMappings) {
        if ([self isCancelled]) return NO;
        
        if ([attributeMapping.sourceKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName]) {
            RKLogTrace(@"Skipping attribute mapping for special keyPath '%@'", attributeMapping.sourceKeyPath);
            continue;
        }

        id value = nil;
        if ([attributeMapping.sourceKeyPath isEqualToString:@""]) {
            value = self.sourceObject;
        } else {
            value = [self.sourceObject valueForKeyPath:attributeMapping.sourceKeyPath];
        }

        if (value) {
            appliedMappings = YES;
            [self applyAttributeMapping:attributeMapping withValue:value];
        } else {
            if ([self.delegate respondsToSelector:@selector(mappingOperation:didNotFindValueForKeyPath:mapping:)]) {
                [self.delegate mappingOperation:self didNotFindValueForKeyPath:attributeMapping.sourceKeyPath mapping:attributeMapping];
            }
            RKLogTrace(@"Did not find mappable attribute value keyPath '%@'", attributeMapping.sourceKeyPath);

            // Optionally set the default value for missing values
            if ([self.objectMapping shouldSetDefaultValueForMissingAttributes]) {
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

- (BOOL)mapNestedObject:(id)anObject toObject:(id)anotherObject withRelationshipMapping:(RKRelationshipMapping *)relationshipMapping
{
    NSAssert(anObject, @"Cannot map nested object without a nested source object");
    NSAssert(anotherObject, @"Cannot map nested object without a destination object");
    NSAssert(relationshipMapping, @"Cannot map a nested object relationship without a relationship mapping");
    NSError *error = nil;

    RKLogTrace(@"Performing nested object mapping using mapping %@ for data: %@", relationshipMapping, anObject);
    RKMappingOperation *subOperation = [[RKMappingOperation alloc] initWithSourceObject:anObject destinationObject:anotherObject mapping:relationshipMapping.mapping];
    subOperation.dataSource = self.dataSource;
    subOperation.delegate = self.delegate;
    [subOperation start];
    
    if (subOperation.error) {
        RKLogWarning(@"WARNING: Failed mapping nested object: %@", [error localizedDescription]);
    }

    return YES;
}

- (BOOL)mapOneToOneRelationshipWithValue:(id)value mapping:(RKRelationshipMapping *)relationshipMapping
{
    // One to one relationship
    RKLogDebug(@"Mapping one to one relationship value at keyPath '%@' to '%@'", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath);

    id destinationObject = [self destinationObjectForMappingRepresentation:value withMapping:relationshipMapping.mapping];
    if (! destinationObject) {
        RKLogDebug(@"Mapping %@ declined mapping for representation %@: returned `nil` destination object.", relationshipMapping.mapping, destinationObject);
        return NO;
    }
    [self mapNestedObject:value toObject:destinationObject withRelationshipMapping:relationshipMapping];

    // If the relationship has changed, set it
    if ([self shouldSetValue:&destinationObject atKeyPath:relationshipMapping.destinationKeyPath]) {
        RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
        [self.destinationObject setValue:destinationObject forKey:relationshipMapping.destinationKeyPath];
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
    for (id nestedObject in value) {
        id mappableObject = [self destinationObjectForMappingRepresentation:nestedObject withMapping:relationshipMapping.mapping];
        if (! mappableObject) {
            RKLogDebug(@"Mapping %@ declined mapping for representation %@: returned `nil` destination object.", relationshipMapping.mapping, nestedObject);
            continue;
        }
        if ([self mapNestedObject:nestedObject toObject:mappableObject withRelationshipMapping:relationshipMapping]) {
            [relationshipCollection addObject:mappableObject];
        }
    }

    id valueForRelationship = relationshipCollection;
    // Transform from NSSet <-> NSArray if necessary
    Class type = [self.objectMapping classForKeyPath:relationshipMapping.destinationKeyPath];
    if (type && NO == [[relationshipCollection class] isSubclassOfClass:type]) {
        valueForRelationship = [self transformValue:relationshipCollection atKeyPath:relationshipMapping.sourceKeyPath toType:type];
    }

    // If the relationship has changed, set it
    if ([self shouldSetValue:&valueForRelationship atKeyPath:relationshipMapping.destinationKeyPath]) {
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
    id destinationObject = nil;

    for (RKRelationshipMapping *relationshipMapping in [self relationshipMappings]) {
        if ([self isCancelled]) return NO;
        
        id value = [self.sourceObject valueForKeyPath:relationshipMapping.sourceKeyPath];

        // Track that we applied this mapping
        [mappingsApplied addObject:relationshipMapping];

        if (value == nil) {
            RKLogDebug(@"Did not find mappable relationship value keyPath '%@'", relationshipMapping.sourceKeyPath);

            // Optionally nil out the property
            id nilReference = nil;
            if ([self.objectMapping setNilForMissingRelationships] && [self shouldSetValue:&nilReference atKeyPath:relationshipMapping.destinationKeyPath]) {
                RKLogTrace(@"Setting nil for missing relationship value at keyPath '%@'", relationshipMapping.sourceKeyPath);
                [self.destinationObject setValue:nil forKeyPath:relationshipMapping.destinationKeyPath];
            }

            continue;
        }
        
        if (value == [NSNull null]) {
            RKLogDebug(@"Found null value at keyPath '%@'", relationshipMapping.sourceKeyPath);
            
            // Optionally nil out the property
            id nilReference = nil;
            if ([self shouldSetValue:&nilReference atKeyPath:relationshipMapping.destinationKeyPath]) {
                RKLogTrace(@"Setting nil for null relationship value at keyPath '%@'", relationshipMapping.sourceKeyPath);
                [self.destinationObject setValue:nil forKeyPath:relationshipMapping.destinationKeyPath];
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
            [self.delegate mappingOperation:self didSetValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping];
        }

        // Fail out if a validation error has occurred
        if (self.error) break;
    }

    return [mappingsApplied count] > 0;
}

- (void)applyNestedMappings
{
    RKAttributeMapping *attributeMapping = [self.objectMapping attributeMappingForKeyOfRepresentation];
    if (attributeMapping) {
        RKLogDebug(@"Found nested mapping definition to attribute '%@'", attributeMapping.destinationKeyPath);
        id attributeValue = [[self.sourceObject allKeys] lastObject];
        if (attributeValue) {
            RKLogDebug(@"Found nesting value of '%@' for attribute '%@'", attributeValue, attributeMapping.destinationKeyPath);
            _nestedAttributeSubstitution = [[NSDictionary alloc] initWithObjectsAndKeys:attributeValue, attributeMapping.destinationKeyPath, nil];
            [self applyAttributeMapping:attributeMapping withValue:attributeValue];
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
    
    RKLogDebug(@"Starting mapping operation...");
    RKLogTrace(@"Performing mapping operation: %@", self);
    
    if (! self.destinationObject) {
        self.destinationObject = [self destinationObjectForMappingRepresentation:self.sourceObject withMapping:self.mapping];
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
    } else if ([self.mapping isKindOfClass:[RKObjectMapping class]]) {
        self.objectMapping = (RKObjectMapping *)self.mapping;
    }

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

    if (self.error) {
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didFailWithError:)]) {
            [self.delegate mappingOperation:self didFailWithError:self.error];
        }

        RKLogError(@"Failed mapping operation: %@", [self.error localizedDescription]);
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
