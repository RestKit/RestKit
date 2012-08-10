//
//  RKObjectMappingOperation.m
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

#import <objc/message.h>
#import "RKObjectMappingOperation.h"
#import "RKObjectMapperError.h"
#import "RKObjectPropertyInspector.h"
#import "RKObjectRelationshipMapping.h"
#import "RKObjectMapper.h"
#import "RKErrors.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitObjectMapping

// Temporary home for object equivalancy tests
BOOL RKObjectIsValueEqualToValue(id sourceValue, id destinationValue);
BOOL RKObjectIsValueEqualToValue(id sourceValue, id destinationValue) {
    NSCAssert(sourceValue, @"Expected sourceValue not to be nil");
    NSCAssert(destinationValue, @"Expected destinationValue not to be nil");

    SEL comparisonSelector;
    if ([sourceValue isKindOfClass:[NSString class]] && [destinationValue isKindOfClass:[NSString class]]) {
        comparisonSelector = @selector(isEqualToString:);
    } else if ([sourceValue isKindOfClass:[NSNumber class]] && [destinationValue isKindOfClass:[NSNumber class]]) {
        comparisonSelector = @selector(isEqualToNumber:);
    } else if ([sourceValue isKindOfClass:[NSDate class]] && [destinationValue isKindOfClass:[NSDate class]]) {
        comparisonSelector = @selector(isEqualToDate:);
    } else if ([sourceValue isKindOfClass:[NSArray class]] && [destinationValue isKindOfClass:[NSArray class]]) {
        comparisonSelector = @selector(isEqualToArray:);
    } else if ([sourceValue isKindOfClass:[NSDictionary class]] && [destinationValue isKindOfClass:[NSDictionary class]]) {
        comparisonSelector = @selector(isEqualToDictionary:);
    } else if ([sourceValue isKindOfClass:[NSSet class]] && [destinationValue isKindOfClass:[NSSet class]]) {
        comparisonSelector = @selector(isEqualToSet:);
    } else {
        comparisonSelector = @selector(isEqual:);
    }

    // Comparison magic using function pointers. See this page for details: http://www.red-sweater.com/blog/320/abusing-objective-c-with-class
    // Original code courtesy of Greg Parker
    // This is necessary because isEqualToNumber will return negative integer values that aren't coercable directly to BOOL's without help [sbw]
    BOOL (*ComparisonSender)(id, SEL, id) = (BOOL (*)(id, SEL, id))objc_msgSend;
    return ComparisonSender(sourceValue, comparisonSelector, destinationValue);
}

@interface RKObjectMappingOperation ()
@property (nonatomic, retain) NSDictionary *nestedAttributeSubstitution;
@property (nonatomic, retain) NSError *validationError;
@end

@implementation RKObjectMappingOperation

@synthesize sourceObject = _sourceObject;
@synthesize destinationObject = _destinationObject;
@synthesize objectMapping = _objectMapping;
@synthesize delegate = _delegate;
@synthesize queue = _queue;
@synthesize nestedAttributeSubstitution = _nestedAttributeSubstitution;
@synthesize validationError = _validationError;

+ (id)mappingOperationFromObject:(id)sourceObject toObject:(id)destinationObject withMapping:(RKObjectMappingDefinition *)objectMapping
{
    // Check for availability of ManagedObjectMappingOperation. Better approach for handling?
    Class targetClass = NSClassFromString(@"RKManagedObjectMappingOperation");
    if (targetClass == nil) targetClass = [RKObjectMappingOperation class];

    return [[[targetClass alloc] initWithSourceObject:sourceObject destinationObject:destinationObject mapping:objectMapping] autorelease];
}

- (id)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject mapping:(RKObjectMappingDefinition *)objectMapping
{
    NSAssert(sourceObject != nil, @"Cannot perform a mapping operation without a sourceObject object");
    NSAssert(destinationObject != nil, @"Cannot perform a mapping operation without a destinationObject");
    NSAssert(objectMapping != nil, @"Cannot perform a mapping operation without a mapping");

    self = [super init];
    if (self) {
        _sourceObject = [sourceObject retain];
        _destinationObject = [destinationObject retain];

        if ([objectMapping isKindOfClass:[RKDynamicObjectMapping class]]) {
            _objectMapping = [[(RKDynamicObjectMapping *)objectMapping objectMappingForDictionary:_sourceObject] retain];
            RKLogDebug(@"RKObjectMappingOperation was initialized with a dynamic mapping. Determined concrete mapping = %@", _objectMapping);
        } else if ([objectMapping isKindOfClass:[RKObjectMapping class]]) {
            _objectMapping = (RKObjectMapping *)[objectMapping retain];
        }
        NSAssert(_objectMapping, @"Cannot perform a mapping operation with an object mapping");
    }

    return self;
}

- (void)dealloc
{
    [_sourceObject release];
    [_destinationObject release];
    [_objectMapping release];
    [_nestedAttributeSubstitution release];
    [_queue release];

    [super dealloc];
}

- (NSDate *)parseDateFromString:(NSString *)string
{
    RKLogTrace(@"Transforming string value '%@' to NSDate...", string);

    NSDate *date = nil;

    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;

    NSNumber *numeric = [numberFormatter numberFromString:string];

    [numberFormatter release];

    if (numeric) {
        date = [NSDate dateWithTimeIntervalSince1970:[numeric doubleValue]];
    } else if (![string isEqualToString:@""]) {
        for (NSFormatter *dateFormatter in self.objectMapping.dateFormatters) {
            BOOL success;
        @synchronized(dateFormatter) {
                if ([dateFormatter isKindOfClass:[NSDateFormatter class]]) {
                    RKLogTrace(@"Attempting to parse string '%@' with format string '%@' and time zone '%@'", string, [(NSDateFormatter *)dateFormatter dateFormat], [(NSDateFormatter *)dateFormatter timeZone]);
                }
                NSString *errorDescription = nil;
                success = [dateFormatter getObjectValue:&date forString:string errorDescription:&errorDescription];
        }

        if (success && date) {
                if ([dateFormatter isKindOfClass:[NSDateFormatter class]]) {
                    RKLogTrace(@"Successfully parsed string '%@' with format string '%@' and time zone '%@' and turned into date '%@'",
                                string, [(NSDateFormatter *)dateFormatter dateFormat], [(NSDateFormatter *)dateFormatter timeZone], date);
                }

                break;
            }
    }
    }

    return date;
}

- (id)transformValue:(id)value atKeyPath:(NSString *)keyPath toType:(Class)destinationType
{
    RKLogTrace(@"Found transformable value at keyPath '%@'. Transforming from type '%@' to '%@'", keyPath, NSStringFromClass([value class]), NSStringFromClass(destinationType));
    Class sourceType = [value class];
    Class orderedSetClass = NSClassFromString(@"NSOrderedSet");

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
    } else if (value == [NSNull null] || [value isEqual:[NSNull null]]) {
        // Transform NSNull -> nil for simplicity
        return nil;
    } else if ([sourceType isSubclassOfClass:[NSSet class]]) {
        // Set -> Array
        if ([destinationType isSubclassOfClass:[NSArray class]]) {
            return [(NSSet *)value allObjects];
        }
    } else if (orderedSetClass && [sourceType isSubclassOfClass:orderedSetClass]) {
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
        if (orderedSetClass && [destinationType isSubclassOfClass:orderedSetClass]) {
            return [orderedSetClass orderedSetWithArray:value];
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
    return RKObjectIsValueEqualToValue(sourceValue, destinationValue);
}

- (BOOL)validateValue:(id *)value atKeyPath:(NSString *)keyPath
{
    BOOL success = YES;

    if (self.objectMapping.performKeyValueValidation && [self.destinationObject respondsToSelector:@selector(validateValue:forKeyPath:error:)]) {
        success = [self.destinationObject validateValue:value forKeyPath:keyPath error:&_validationError];
        if (!success) {
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
    if (currentValue == [NSNull null] || [currentValue isEqual:[NSNull null]]) {
        currentValue = nil;
    }

    /*
     WTF - This workaround should not be necessary, but I have been unable to replicate
     the circumstances that trigger it in a unit test to fix elsewhere. The proper place
     to handle it is in transformValue:atKeyPath:toType:

     See issue & pull request: https://github.com/RestKit/RestKit/pull/436
     */
    if (*value == [NSNull null] || [*value isEqual:[NSNull null]]) {
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
        for (RKObjectAttributeMapping *mapping in mappings) {
            RKObjectAttributeMapping *nestedMapping = [mapping copy];
            nestedMapping.sourceKeyPath = [nestedMapping.sourceKeyPath stringByReplacingOccurrencesOfString:searchString withString:replacementString];
            nestedMapping.destinationKeyPath = [nestedMapping.destinationKeyPath stringByReplacingOccurrencesOfString:searchString withString:replacementString];
            [array addObject:nestedMapping];
            [nestedMapping release];
        }

        return array;
    }

    return mappings;
}

- (NSArray *)attributeMappings
{
    return [self applyNestingToMappings:self.objectMapping.attributeMappings];
}

- (NSArray *)relationshipMappings
{
    return [self applyNestingToMappings:self.objectMapping.relationshipMappings];
}

- (void)applyAttributeMapping:(RKObjectAttributeMapping *)attributeMapping withValue:(id)value
{
    if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didFindMapping:forKeyPath:)]) {
        [self.delegate objectMappingOperation:self didFindMapping:attributeMapping forKeyPath:attributeMapping.sourceKeyPath];
    }
    RKLogTrace(@"Mapping attribute value keyPath '%@' to '%@'", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath);

    // Inspect the property type to handle any value transformations
    Class type = [self.objectMapping classForProperty:attributeMapping.destinationKeyPath];
    if (type && NO == [[value class] isSubclassOfClass:type]) {
        value = [self transformValue:value atKeyPath:attributeMapping.sourceKeyPath toType:type];
    }

    // Ensure that the value is different
    if ([self shouldSetValue:&value atKeyPath:attributeMapping.destinationKeyPath]) {
        RKLogTrace(@"Mapped attribute value from keyPath '%@' to '%@'. Value: %@", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath, value);

        [self.destinationObject setValue:value forKeyPath:attributeMapping.destinationKeyPath];
        if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didSetValue:forKeyPath:usingMapping:)]) {
            [self.delegate objectMappingOperation:self didSetValue:value forKeyPath:attributeMapping.destinationKeyPath usingMapping:attributeMapping];
        }
    } else {
        RKLogTrace(@"Skipped mapping of attribute value from keyPath '%@ to keyPath '%@' -- value is unchanged (%@)", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath, value);
        if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
            [self.delegate objectMappingOperation:self didNotSetUnchangedValue:value forKeyPath:attributeMapping.destinationKeyPath usingMapping:attributeMapping];
        }
    }
}

// Return YES if we mapped any attributes
- (BOOL)applyAttributeMappings
{
    // If we have a nesting substitution value, we have alread
    BOOL appliedMappings = (_nestedAttributeSubstitution != nil);

    if (!self.objectMapping.performKeyValueValidation) {
        RKLogDebug(@"Key-value validation is disabled for mapping, skipping...");
    }

    for (RKObjectAttributeMapping *attributeMapping in [self attributeMappings]) {
        if ([attributeMapping isMappingForKeyOfNestedDictionary]) {
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
            if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didNotFindMappingForKeyPath:)]) {
                [self.delegate objectMappingOperation:self didNotFindMappingForKeyPath:attributeMapping.sourceKeyPath];
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

- (BOOL)isTypeACollection:(Class)type
{
    Class orderedSetClass = NSClassFromString(@"NSOrderedSet");
    return (type && ([type isSubclassOfClass:[NSSet class]] ||
                     [type isSubclassOfClass:[NSArray class]] ||
                     (orderedSetClass && [type isSubclassOfClass:orderedSetClass])));
}

- (BOOL)isValueACollection:(id)value
{
    return [self isTypeACollection:[value class]];
}

- (BOOL)mapNestedObject:(id)anObject toObject:(id)anotherObject withRealtionshipMapping:(RKObjectRelationshipMapping *)relationshipMapping
{
    NSAssert(anObject, @"Cannot map nested object without a nested source object");
    NSAssert(anotherObject, @"Cannot map nested object without a destination object");
    NSAssert(relationshipMapping, @"Cannot map a nested object relationship without a relationship mapping");
    NSError *error = nil;

    RKLogTrace(@"Performing nested object mapping using mapping %@ for data: %@", relationshipMapping, anObject);
    RKObjectMappingOperation *subOperation = [RKObjectMappingOperation mappingOperationFromObject:anObject toObject:anotherObject withMapping:relationshipMapping.mapping];
    subOperation.delegate = self.delegate;
    subOperation.queue = self.queue;
    if (NO == [subOperation performMapping:&error]) {
        RKLogWarning(@"WARNING: Failed mapping nested object: %@", [error localizedDescription]);
    }

    return YES;
}

- (BOOL)applyRelationshipMappings
{
    BOOL appliedMappings = NO;
    id destinationObject = nil;

    for (RKObjectRelationshipMapping *relationshipMapping in [self relationshipMappings]) {
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

        if (value == nil || value == [NSNull null] || [value isEqual:[NSNull null]]) {
            RKLogDebug(@"Did not find mappable relationship value keyPath '%@'", relationshipMapping.sourceKeyPath);

            // Optionally nil out the property
            id nilReference = nil;
            if ([self.objectMapping setNilForMissingRelationships] && [self shouldSetValue:&nilReference atKeyPath:relationshipMapping.destinationKeyPath]) {
                RKLogTrace(@"Setting nil for missing relationship value at keyPath '%@'", relationshipMapping.sourceKeyPath);
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
        Class relationshipType = [self.objectMapping classForProperty:relationshipMapping.destinationKeyPath];
        BOOL mappingToCollection = [self isTypeACollection:relationshipType];
        if (mappingToCollection && ![self isValueACollection:value]) {
            Class orderedSetClass = NSClassFromString(@"NSOrderedSet");
            RKLogDebug(@"Asked to map a single object into a collection relationship. Transforming to an instance of: %@", NSStringFromClass(relationshipType));
            if ([relationshipType isSubclassOfClass:[NSArray class]]) {
                value = [relationshipType arrayWithObject:value];
            } else if ([relationshipType isSubclassOfClass:[NSSet class]]) {
                value = [relationshipType setWithObject:value];
            } else if (orderedSetClass && [relationshipType isSubclassOfClass:orderedSetClass]) {
                value = [relationshipType orderedSetWithObject:value];
            } else {
                RKLogWarning(@"Failed to transform single object");
            }
        }

        if ([self isValueACollection:value]) {
            // One to many relationship
            RKLogDebug(@"Mapping one to many relationship value at keyPath '%@' to '%@'", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath);
            appliedMappings = YES;

            destinationObject = [NSMutableArray arrayWithCapacity:[value count]];
            id collectionSanityCheckObject = nil;
            if ([value respondsToSelector:@selector(anyObject)]) collectionSanityCheckObject = [value anyObject];
            if ([value respondsToSelector:@selector(lastObject)]) collectionSanityCheckObject = [value lastObject];
            if ([self isValueACollection:collectionSanityCheckObject]) {
                RKLogWarning(@"WARNING: Detected a relationship mapping for a collection containing another collection. This is probably not what you want. Consider using a KVC collection operator (such as @unionOfArrays) to flatten your mappable collection.");
                RKLogWarning(@"Key path '%@' yielded collection containing another collection rather than a collection of objects: %@", relationshipMapping.sourceKeyPath, value);
            }
            for (id nestedObject in value) {
                RKObjectMappingDefinition *mapping = relationshipMapping.mapping;
                RKObjectMapping *objectMapping = nil;
                if ([mapping isKindOfClass:[RKDynamicObjectMapping class]]) {
                    objectMapping = [(RKDynamicObjectMapping *)mapping objectMappingForDictionary:nestedObject];
                    if (! objectMapping) {
                        RKLogDebug(@"Mapping %@ declined mapping for data %@: returned nil objectMapping", mapping, nestedObject);
                        continue;
                    }
                } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
                    objectMapping = (RKObjectMapping *)mapping;
                } else {
                    NSAssert(objectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
                }
                id mappedObject = [objectMapping mappableObjectForData:nestedObject];
                if ([self mapNestedObject:nestedObject toObject:mappedObject withRealtionshipMapping:relationshipMapping]) {
                    [destinationObject addObject:mappedObject];
                }
            }

            // Transform from NSSet <-> NSArray if necessary
            Class type = [self.objectMapping classForProperty:relationshipMapping.destinationKeyPath];
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
                        NSMutableSet *destinationSet = [self.destinationObject mutableSetValueForKey:relationshipMapping.destinationKeyPath];
                        [destinationSet setSet:destinationObject];
                    } else if ([destinationObject isKindOfClass:[NSArray class]]) {
                        RKLogTrace(@"Mapped NSArray relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                        NSMutableArray *destinationArray = [self.destinationObject mutableArrayValueForKey:relationshipMapping.destinationKeyPath];
                        [destinationArray setArray:destinationObject];
                    } else if (nsOrderedSetClass && [destinationObject isKindOfClass:nsOrderedSetClass]) {
                        RKLogTrace(@"Mapped NSOrderedSet relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                        [self.destinationObject setValue:destinationObject forKey:relationshipMapping.destinationKeyPath];
                    }
                } else {
                    RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                    [self.destinationObject setValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath];
                }
            } else {
                if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
                    [self.delegate objectMappingOperation:self didNotSetUnchangedValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping];
                }
            }
        } else {
            // One to one relationship
            RKLogDebug(@"Mapping one to one relationship value at keyPath '%@' to '%@'", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath);

            RKObjectMappingDefinition *mapping = relationshipMapping.mapping;
            RKObjectMapping *objectMapping = nil;
            if ([mapping isKindOfClass:[RKDynamicObjectMapping class]]) {
                objectMapping = [(RKDynamicObjectMapping *)mapping objectMappingForDictionary:value];
            } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
                objectMapping = (RKObjectMapping *)mapping;
            }
            NSAssert(objectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
            destinationObject = [objectMapping mappableObjectForData:value];
            if ([self mapNestedObject:value toObject:destinationObject withRealtionshipMapping:relationshipMapping]) {
                appliedMappings = YES;
            }

            // If the relationship has changed, set it
            if ([self shouldSetValue:&destinationObject atKeyPath:relationshipMapping.destinationKeyPath]) {
                appliedMappings = YES;
                RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                [self.destinationObject setValue:destinationObject forKey:relationshipMapping.destinationKeyPath];
            } else {
                if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didNotSetUnchangedValue:forKeyPath:usingMapping:)]) {
                    [self.delegate objectMappingOperation:self didNotSetUnchangedValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping];
                }
            }
        }

        // Notify the delegate
        if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didSetValue:forKeyPath:usingMapping:)]) {
            [self.delegate objectMappingOperation:self didSetValue:destinationObject forKeyPath:relationshipMapping.destinationKeyPath usingMapping:relationshipMapping];
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
    RKObjectAttributeMapping *attributeMapping = [self.objectMapping attributeMappingForKeyOfNestedDictionary];
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

- (BOOL)performMapping:(NSError **)error
{
    RKLogDebug(@"Starting mapping operation...");
    RKLogTrace(@"Performing mapping operation: %@", self);

    [self applyNestedMappings];
    BOOL mappedAttributes = [self applyAttributeMappings];
    BOOL mappedRelationships = [self applyRelationshipMappings];
    if ((mappedAttributes || mappedRelationships) && _validationError == nil) {
        RKLogDebug(@"Finished mapping operation successfully...");
        return YES;
    }

    if (_validationError) {
        // We failed out due to validation
        if (error) *error = _validationError;
        if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didFailWithError:)]) {
            [self.delegate objectMappingOperation:self didFailWithError:_validationError];
        }

        RKLogError(@"Failed mapping operation: %@", [_validationError localizedDescription]);
    } else {
        // We did not find anything to do
        RKLogDebug(@"Mapping operation did not find any mappable content");
    }

    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"RKObjectMappingOperation for '%@' object. Mapping values from object %@ to object %@ with object mapping %@",
            NSStringFromClass([self.destinationObject class]), self.sourceObject, self.destinationObject, self.objectMapping];
}

@end
