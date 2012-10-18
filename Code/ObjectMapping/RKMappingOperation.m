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

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitObjectMapping

extern NSString * const RKObjectMappingNestingAttributeKeyName;

@interface RKMappingOperation ()
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, strong, readwrite) id sourceObject;
@property (nonatomic, strong, readwrite) id destinationObject;
@property (nonatomic, strong) NSDictionary *nestedAttributeSubstitution;
@property (nonatomic, strong) NSError *validationError;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong) RKObjectMapping *objectMapping; // The concrete mapping
@end

// Defined in RKObjectMapping.h
NSDate *RKDateFromStringWithFormatters(NSString *dateString, NSArray *formatters);

/**
 This method ensures that attribute mappings apply cleanly to an `NSMutableDictionary` target class to support mapping to nested keyPaths. See issue #882
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

@implementation RKMappingOperation

- (id)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject mapping:(RKMapping *)objectOrDynamicMapping
{
    NSAssert(sourceObject != nil, @"Cannot perform a mapping operation without a sourceObject object");
    NSAssert(destinationObject != nil, @"Cannot perform a mapping operation without a destinationObject");
    NSAssert(objectOrDynamicMapping != nil, @"Cannot perform a mapping operation without a mapping");

    self = [super init];
    if (self) {
        self.sourceObject = sourceObject;
        self.destinationObject = destinationObject;
        self.mapping = objectOrDynamicMapping;
    }

    return self;
}


- (NSDate *)parseDateFromString:(NSString *)string
{
    RKLogTrace(@"Transforming string value '%@' to NSDate...", string);
    return RKDateFromStringWithFormatters(string, self.objectMapping.dateFormatters);
}

- (id)transformValue:(id)value atKeyPath:(NSString *)keyPath toType:(Class)destinationType
{
    RKLogTrace(@"Found transformable value at keyPath '%@'. Transforming from type '%@' to '%@'", keyPath, NSStringFromClass([value class]), NSStringFromClass(destinationType));
    Class sourceType = [value class];

    if ([sourceType isSubclassOfClass:[NSString class]]) {
        if ([destinationType isSubclassOfClass:[NSDate class]]) {
            // String -> Date
            return [self parseDateFromString:(NSString *)value];
        } else if ([destinationType isSubclassOfClass:[NSURL class]]) {
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
    } else if (value == [NSNull null]) {
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
    } else if ([destinationType isSubclassOfClass:[NSString class]] && [value isKindOfClass:[NSDate class]]) {
        // NSDate -> NSString
        // Transform using the preferred date formatter
        NSString *dateString = nil;
        @synchronized(self.objectMapping.preferredDateFormatter) {
            dateString = [self.objectMapping.preferredDateFormatter stringForObjectValue:value];
        }
        return dateString;
    }

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
            _validationError = validationError;
            if (_validationError) {
                RKLogError(@"Validation failed while mapping attribute at key path '%@' to value %@. Error: %@", keyPath, *value, [_validationError localizedDescription]);
                RKLogValidationError(_validationError);
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
        NSString *searchString = [NSString stringWithFormat:@"(%@)", [[_nestedAttributeSubstitution allKeys] lastObject]];
        NSString *replacementString = [[_nestedAttributeSubstitution allValues] lastObject];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self.objectMapping.attributeMappings count]];
        for (RKPropertyMapping *mapping in mappings) {
            NSString *sourceKeyPath = [mapping.sourceKeyPath stringByReplacingOccurrencesOfString:searchString withString:replacementString];
            NSString *destinationKeyPath = [mapping.destinationKeyPath stringByReplacingOccurrencesOfString:searchString withString:replacementString];
            RKPropertyMapping *nestedMapping = nil;
            if ([mapping isKindOfClass:[RKAttributeMapping class]]) {
                nestedMapping = [RKAttributeMapping attributeMappingFromKeyPath:sourceKeyPath toKeyPath:mapping.destinationKeyPath];
            } else if ([mapping isKindOfClass:[RKRelationshipMapping class]]) {
                nestedMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:sourceKeyPath
                                                                            toKeyPath:destinationKeyPath
                                                                          withMapping:[(RKRelationshipMapping *)mapping mapping]];
            }
            [array addObject:nestedMapping];
        }

        return array;
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
    // If we have a nesting substitution value, we have alread
    BOOL appliedMappings = (_nestedAttributeSubstitution != nil);

    if (!self.objectMapping.performKeyValueValidation) {
        RKLogDebug(@"Key-value validation is disabled for mapping, skipping...");
    }

    for (RKAttributeMapping *attributeMapping in attributeMappings) {
        if ([attributeMapping.sourceKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName]) {
            RKLogTrace(@"Skipping attribute mapping for special keyPath '%@'", attributeMapping.sourceKeyPath);
            continue;
        }

        if (self.objectMapping.ignoreUnknownKeyPaths && ![self.sourceObject respondsToSelector:NSSelectorFromString(attributeMapping.sourceKeyPath)]) {
            RKLogDebug(@"Source object is not key-value coding compliant for the keyPath '%@', skipping...", attributeMapping.sourceKeyPath);
            continue;
        }

        id value = nil;
        @try {
            if ([attributeMapping.sourceKeyPath isEqualToString:@""]) {
                value = self.sourceObject;
            } else {
                value = [self.sourceObject valueForKeyPath:attributeMapping.sourceKeyPath];
            }
        }
        @catch (NSException *exception) {
            if ([[exception name] isEqualToString:NSUndefinedKeyException] && self.objectMapping.ignoreUnknownKeyPaths) {
                RKLogWarning(@"Encountered an undefined attribute mapping for keyPath '%@' that generated NSUndefinedKeyException exception. Skipping due to objectMapping.ignoreUnknownKeyPaths = YES",
                           attributeMapping.sourceKeyPath);
                continue;
            }

            @throw;
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
                [self.destinationObject setValue:[self.objectMapping defaultValueForMissingAttribute:attributeMapping.destinationKeyPath]
                                      forKeyPath:attributeMapping.destinationKeyPath];
                RKLogTrace(@"Setting nil for missing attribute value at keyPath '%@'", attributeMapping.sourceKeyPath);
            }
        }

        // Fail out if an error has occurred
        if (_validationError) {
            return NO;
        }
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

- (BOOL)applyRelationshipMappings
{
    NSAssert(self.dataSource, @"Cannot perform relationship mapping without a data source");
    BOOL appliedMappings = NO;
    id destinationObject = nil;

    for (RKRelationshipMapping *relationshipMapping in [self relationshipMappings]) {
        id value = nil;
        @try {
            value = [self.sourceObject valueForKeyPath:relationshipMapping.sourceKeyPath];
        }
        @catch (NSException *exception) {
            if ([[exception name] isEqualToString:NSUndefinedKeyException] && self.objectMapping.ignoreUnknownKeyPaths) {
                RKLogWarning(@"Encountered an undefined relationship mapping for keyPath '%@' that generated NSUndefinedKeyException exception. Skipping due to objectMapping.ignoreUnknownKeyPaths = YES",
                             relationshipMapping.sourceKeyPath);
                continue;
            }

            @throw;
        }

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

        if (RKObjectIsCollection(value)) {
            // One to many relationship
            RKLogDebug(@"Mapping one to many relationship value at keyPath '%@' to '%@'", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath);
            appliedMappings = YES;

            destinationObject = [NSMutableArray arrayWithCapacity:[value count]];
            id collectionSanityCheckObject = nil;
            if ([value respondsToSelector:@selector(anyObject)]) collectionSanityCheckObject = [value anyObject];
            if ([value respondsToSelector:@selector(lastObject)]) collectionSanityCheckObject = [value lastObject];
            if (RKObjectIsCollection(collectionSanityCheckObject)) {
                RKLogWarning(@"WARNING: Detected a relationship mapping for a collection containing another collection. This is probably not what you want. Consider using a KVC collection operator (such as @unionOfArrays) to flatten your mappable collection.");
                RKLogWarning(@"Key path '%@' yielded collection containing another collection rather than a collection of objects: %@", relationshipMapping.sourceKeyPath, value);
            }
            for (id nestedObject in value) {
                RKMapping *mapping = relationshipMapping.mapping;
                RKObjectMapping *objectMapping = nil;
                if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
                    objectMapping = [(RKDynamicMapping *)mapping objectMappingForRepresentation:nestedObject];
                    if (! objectMapping) {
                        RKLogDebug(@"Mapping %@ declined mapping for data %@: returned nil objectMapping", mapping, nestedObject);
                        continue;
                    }
                } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
                    objectMapping = (RKObjectMapping *)mapping;
                } else {
                    NSAssert(objectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
                }
                id mappableObject = [self.dataSource mappingOperation:self targetObjectForRepresentation:nestedObject withMapping:objectMapping];
                if ([self mapNestedObject:nestedObject toObject:mappableObject withRelationshipMapping:relationshipMapping]) {
                    [destinationObject addObject:mappableObject];
                }
            }

            // Transform from NSSet <-> NSArray if necessary
            Class type = [self.objectMapping classForKeyPath:relationshipMapping.destinationKeyPath];
            if (type && NO == [[destinationObject class] isSubclassOfClass:type]) {
                destinationObject = [self transformValue:destinationObject atKeyPath:relationshipMapping.sourceKeyPath toType:type];
            }

            // If the relationship has changed, set it
            if ([self shouldSetValue:&destinationObject atKeyPath:relationshipMapping.destinationKeyPath]) {
                Class managedObjectClass = NSClassFromString(@"NSManagedObject");
                Class nsOrderedSetClass = NSClassFromString(@"NSOrderedSet");
                if (managedObjectClass && [self.destinationObject isKindOfClass:managedObjectClass]) {
                    RKLogTrace(@"Found a managedObject collection. About to apply value via mutable[Set|Array]ValueForKey");
                    if ([destinationObject isKindOfClass:[NSSet class]]) {
                        RKLogTrace(@"Mapped NSSet relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                        NSMutableSet *destinationSet = [self.destinationObject mutableSetValueForKeyPath:relationshipMapping.destinationKeyPath];
                        if ([relationshipMapping.destinationKeyPath isEqualToString:@"departureAirport.checkpoints"]) {
                        }
                       [destinationSet setSet:destinationObject];
                    } else if ([destinationObject isKindOfClass:[NSArray class]]) {
                        RKLogTrace(@"Mapped NSArray relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                        NSMutableArray *destinationArray = [self.destinationObject mutableArrayValueForKeyPath:relationshipMapping.destinationKeyPath];
                        [destinationArray setArray:destinationObject];
                    } else if (nsOrderedSetClass && [destinationObject isKindOfClass:nsOrderedSetClass]) {
                        RKLogTrace(@"Mapped NSOrderedSet relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                        [self.destinationObject setValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath];
                    }
                } else {
                    RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                    [self.destinationObject setValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath];
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(mappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
                    [self.delegate mappingOperation:self didNotSetUnchangedValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping];
                }
            }
        } else {
            // One to one relationship
            RKLogDebug(@"Mapping one to one relationship value at keyPath '%@' to '%@'", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath);

            RKMapping *mapping = relationshipMapping.mapping;
            RKObjectMapping *objectMapping = nil;
            if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
                objectMapping = [(RKDynamicMapping *)mapping objectMappingForRepresentation:value];
            } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
                objectMapping = (RKObjectMapping *)mapping;
            }
            NSAssert(objectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
            destinationObject = [self.dataSource mappingOperation:self targetObjectForRepresentation:value withMapping:objectMapping];
            if ([self mapNestedObject:value toObject:destinationObject withRelationshipMapping:relationshipMapping]) {
                appliedMappings = YES;
            }

            // If the relationship has changed, set it
            if ([self shouldSetValue:&destinationObject atKeyPath:relationshipMapping.destinationKeyPath]) {
                appliedMappings = YES;
                RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                [self.destinationObject setValue:destinationObject forKey:relationshipMapping.destinationKeyPath];
            } else {
                if ([self.delegate respondsToSelector:@selector(mappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
                    [self.delegate mappingOperation:self didNotSetUnchangedValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping];
                }
            }
        }

        // Notify the delegate
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didSetValue:forKeyPath:usingMapping:)]) {
            [self.delegate mappingOperation:self didSetValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping];
        }

        // Fail out if a validation error has occurred
        if (_validationError) {
            return NO;
        }
    }

    return appliedMappings;
}

- (void)applyNestedMappings
{
    RKAttributeMapping *attributeMapping = [self.objectMapping attributeMappingForKeyOfNestedDictionary];
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

- (void)main
{
    RKLogDebug(@"Starting mapping operation...");
    RKLogTrace(@"Performing mapping operation: %@", self);
    
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
    BOOL mappedSimpleAttributes = [self applyAttributeMappings:[self simpleAttributeMappings]];
    BOOL mappedRelationships = [self applyRelationshipMappings];
    BOOL mappedKeyPathAttributes = [self applyAttributeMappings:[self keyPathAttributeMappings]];
    if ((mappedSimpleAttributes || mappedKeyPathAttributes || mappedRelationships) && _validationError == nil) {
        RKLogDebug(@"Finished mapping operation successfully...");

        if ([self.dataSource respondsToSelector:@selector(commitChangesForMappingOperation:)]) {
            [self.dataSource commitChangesForMappingOperation:self];
        }
        return;
    }

    if (self.validationError) {
        // We failed out due to validation
        self.error = _validationError;
        if ([self.delegate respondsToSelector:@selector(mappingOperation:didFailWithError:)]) {
            [self.delegate mappingOperation:self didFailWithError:self.error];
        }

        RKLogError(@"Failed mapping operation: %@", [self.error localizedDescription]);
    } else {
        // We did not find anything to do
        RKLogDebug(@"Mapping operation did not find any mappable values for the attribute and relationship mappings in the given object representation");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"No mappable values found for any of the attributes or relationship mappings" };
        self.error = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorUnmappableRepresentation userInfo:userInfo];
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
    return [NSString stringWithFormat:@"RKObjectMappingOperation for '%@' object. Mapping values from object %@ to object %@ with object mapping %@",
            NSStringFromClass([self.destinationObject class]), self.sourceObject, self.destinationObject, self.objectMapping];
}

@end
