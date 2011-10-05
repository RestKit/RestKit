
//
//  RKObjectMappingOperation.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters
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
#import "../Support/Errors.h"
#import "../Support/RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitObjectMapping

extern NSString* const RKObjectMappingNestingAttributeKeyName;

// Temporary home for object equivalancy tests
BOOL RKObjectIsValueEqualToValue(id sourceValue, id destinationValue) {
    NSCAssert(sourceValue, @"Expected sourceValue not to be nil");
    NSCAssert(destinationValue, @"Expected destinationValue not to be nil");
    
    SEL comparisonSelector;
    if ([sourceValue isKindOfClass:[NSString class]]) {
        comparisonSelector = @selector(isEqualToString:);
    } else if ([sourceValue isKindOfClass:[NSNumber class]]) {
        comparisonSelector = @selector(isEqualToNumber:);
    } else if ([sourceValue isKindOfClass:[NSDate class]]) {
        comparisonSelector = @selector(isEqualToDate:);
    } else if ([sourceValue isKindOfClass:[NSArray class]]) {
        comparisonSelector = @selector(isEqualToArray:);
    } else if ([sourceValue isKindOfClass:[NSDictionary class]]) {
        comparisonSelector = @selector(isEqualToDictionary:);
    } else if ([sourceValue isKindOfClass:[NSSet class]]) {
        comparisonSelector = @selector(isEqualToSet:);
    } else {
        comparisonSelector = @selector(isEqual:);
    }
    
    // Comparison magic using function pointers. See this page for details: http://www.red-sweater.com/blog/320/abusing-objective-c-with-class
    // Original code courtesy of Greg Parker
    // This is necessary because isEqualToNumber will return negative integer values that aren't coercable directly to BOOL's without help [sbw]
    BOOL (*ComparisonSender)(id, SEL, id) = (BOOL (*)(id, SEL, id)) objc_msgSend;
    return ComparisonSender(sourceValue, comparisonSelector, destinationValue);
}

@implementation RKObjectMappingOperation

@synthesize sourceObject = _sourceObject;
@synthesize destinationObject = _destinationObject;
@synthesize objectMapping = _objectMapping;
@synthesize delegate = _delegate;
@synthesize queue = _queue;

+ (RKObjectMappingOperation*)mappingOperationFromObject:(id)sourceObject toObject:(id)destinationObject withMapping:(id<RKObjectMappingDefinition>)objectMapping {
    return [[[self alloc] initWithSourceObject:sourceObject destinationObject:destinationObject mapping:objectMapping] autorelease];
}

- (id)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject mapping:(id<RKObjectMappingDefinition>)objectMapping {
    NSAssert(sourceObject != nil, @"Cannot perform a mapping operation without a sourceObject object");
    NSAssert(destinationObject != nil, @"Cannot perform a mapping operation without a destinationObject");
    NSAssert(objectMapping != nil, @"Cannot perform a mapping operation without a mapping");
    
    self = [super init];
    if (self) {
        _sourceObject = [sourceObject retain];        
        _destinationObject = [destinationObject retain];
        
        if ([objectMapping isKindOfClass:[RKDynamicObjectMapping class]]) {
            _objectMapping = [[(RKDynamicObjectMapping*)objectMapping objectMappingForDictionary:_sourceObject] retain];
            RKLogDebug(@"RKObjectMappingOperation was initialized with a dynamic mapping. Determined concrete mapping = %@", _objectMapping);
        } else if ([objectMapping isKindOfClass:[RKObjectMapping class]]) {
            _objectMapping = (RKObjectMapping*)[objectMapping retain];
        }
        NSAssert(_objectMapping, @"Cannot perform a mapping operation with an object mapping");
    }    
    
    return self;
}

- (void)dealloc {
    [_sourceObject release];
    [_destinationObject release];
    [_objectMapping release];
    [_nestedAttributeSubstitution release];
    
    [super dealloc];
}

- (NSDate*)parseDateFromString:(NSString*)string {
    RKLogTrace(@"Transforming string value '%@' to NSDate...", string);
    
	NSDate* date = nil;
    for (NSDateFormatter *dateFormatter in self.objectMapping.dateFormatters) {
        @synchronized(dateFormatter) {
            date = [dateFormatter dateFromString:string];
        }
        if (date) {
			break;
		}
    }
    
    return date;
}

- (BOOL)isValue:(id)sourceValue equalToValue:(id)destinationValue {    
    return RKObjectIsValueEqualToValue(sourceValue, destinationValue);
}

- (BOOL)validateValue:(id)value atKeyPath:(NSString*)keyPath {
    BOOL success = YES;        
    
    if (self.objectMapping.performKeyValueValidation && [self.destinationObject respondsToSelector:@selector(validateValue:forKey:error:)]) {
        success = [self.destinationObject validateValue:&value forKey:keyPath error:&_validationError];
        if (!success) {                        
            if (_validationError) {
                RKLogError(@"Validation failed while mapping attribute at key path %@ to value %@. Error: %@", keyPath, value, [_validationError localizedDescription]);
            } else {
                RKLogWarning(@"Destination object %@ rejected attribute value %@ for keyPath %@. Skipping...", self.destinationObject, value, keyPath);
            }
        }
    }
    
    return success;
}

- (BOOL)shouldSetValue:(id)value atKeyPath:(NSString*)keyPath {
    id currentValue = [self.destinationObject valueForKeyPath:keyPath];
    if (currentValue == [NSNull null] || [currentValue isEqual:[NSNull null]]) {
        currentValue = nil;
    }
    
	if (nil == currentValue && nil == value) {
		// Both are nil
        return NO;
	} else if (nil == value || nil == currentValue) {
		// One is nil and the other is not
        return [self validateValue:value atKeyPath:keyPath];
	}
    
    if (! [self isValue:value equalToValue:currentValue]) {
        // Validate value for key
        return [self validateValue:value atKeyPath:keyPath];
    }
    return NO;
}

- (NSArray*)applyNestingToMappings:(NSArray*)mappings {
    if (_nestedAttributeSubstitution) {
        NSString* searchString = [NSString stringWithFormat:@"(%@)", [[_nestedAttributeSubstitution allKeys] lastObject]];
        NSString* replacementString = [[_nestedAttributeSubstitution allValues] lastObject];
        NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self.objectMapping.attributeMappings count]];
        for (RKObjectAttributeMapping* mapping in mappings) {
            RKObjectAttributeMapping* nestedMapping = [mapping copy];
            nestedMapping.sourceKeyPath = [nestedMapping.sourceKeyPath stringByReplacingOccurrencesOfString:searchString withString:replacementString];
            nestedMapping.destinationKeyPath = [nestedMapping.destinationKeyPath stringByReplacingOccurrencesOfString:searchString withString:replacementString];
            [array addObject:nestedMapping];
            [nestedMapping release];
        }
        
        return array;
    }
    
    return mappings;
}

- (NSArray*)attributeMappings {
    return [self applyNestingToMappings:self.objectMapping.attributeMappings];
}

- (NSArray*)relationshipMappings {
    return [self applyNestingToMappings:self.objectMapping.relationshipMappings];
}

- (void)applyAttributeMapping:(RKObjectAttributeMapping*)attributeMapping withValue:(id)value {
    if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didFindMapping:forKeyPath:)]) {
        [self.delegate objectMappingOperation:self didFindMapping:attributeMapping forKeyPath:attributeMapping.sourceKeyPath];
    }
    RKLogTrace(@"Mapping attribute value keyPath '%@' to '%@'", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath);
        
    // Ensure that the value is different
    if ([self shouldSetValue:value atKeyPath:attributeMapping.destinationKeyPath]) {
        RKLogTrace(@"Mapped attribute value from keyPath '%@' to '%@'. Value: %@", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath, value);
        
        [self.destinationObject setValue:value forKey:attributeMapping.destinationKeyPath];
        if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didSetValue:forKeyPath:usingMapping:)]) {
            [self.delegate objectMappingOperation:self didSetValue:value forKeyPath:attributeMapping.destinationKeyPath usingMapping:attributeMapping];
        }        
    } else {
        RKLogTrace(@"Skipped mapping of attribute value from keyPath '%@ to keyPath '%@' -- value is unchanged (%@)", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath, value);
    }
}

// Return YES if we mapped any attributes
- (BOOL)applyAttributeMappings {
    // If we have a nesting substitution value, we have alread
    BOOL appliedMappings = (_nestedAttributeSubstitution != nil);
    
    if (!self.objectMapping.performKeyValueValidation) {
        RKLogDebug(@"Key-value validation is disabled for mapping, skipping...");
    }
    
    RKDefaultTransformer* defaultTransformer = [RKDefaultTransformer transformerWithObjectMapping:self.objectMapping];
    NSError *err = nil;
    
    for (RKObjectAttributeMapping* attributeMapping in [self attributeMappings]) {
        if ([attributeMapping.sourceKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName]) {
            RKLogTrace(@"Skipping attribute mapping for special keyPath '%@'", RKObjectMappingNestingAttributeKeyName);
            continue;
        }
        
        Class type = [self.objectMapping classForProperty:attributeMapping.destinationKeyPath];
        id value = [attributeMapping valueFromSourceObject:self.sourceObject destinationType:type defaultTransformer:defaultTransformer error:&err];
        if (err)
        {
            RKLogWarning(@"Failed transformation of value at keyPath '%@'. %@", attributeMapping.sourceKeyPath, err);
            err = nil;
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
                                          forKey:attributeMapping.destinationKeyPath];
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

- (BOOL)isValueACollection:(id)value {
    return ([value isKindOfClass:[NSSet class]] || [value isKindOfClass:[NSArray class]]);
}

- (BOOL)mapNestedObject:(id)anObject toObject:(id)anotherObject withRealtionshipMapping:(RKObjectRelationshipMapping*)relationshipMapping {
    NSAssert(anObject, @"Cannot map nested object without a nested source object");
    NSAssert(anotherObject, @"Cannot map nested object without a destination object");
    NSAssert(relationshipMapping, @"Cannot map a nested object relationship without a relationship mapping");
    NSError* error = nil;
    
    RKObjectMappingOperation* subOperation = [RKObjectMappingOperation mappingOperationFromObject:anObject toObject:anotherObject withMapping:relationshipMapping.mapping];
    subOperation.delegate = self.delegate;
    subOperation.queue = self.queue;
    if (NO == [subOperation performMapping:&error]) {
        RKLogWarning(@"WARNING: Failed mapping nested object: %@", [error localizedDescription]);
    }
    
    return YES;
}

- (BOOL)applyRelationshipMappings {
    BOOL appliedMappings = NO;
    id destinationObject = nil;
    
    RKDefaultTransformer *transform = [RKDefaultTransformer transformerWithObjectMapping:self.objectMapping];
    for (RKObjectRelationshipMapping* relationshipMapping in [self relationshipMappings]) {
        Class relationshipType = [self.objectMapping classForProperty:relationshipMapping.destinationKeyPath];
        NSError *err = nil;
        id value = [relationshipMapping valueFromSourceObject:self.sourceObject destinationType:relationshipType defaultTransformer:nil error:&err];
        
        if (value == nil || value == [NSNull null] || [value isEqual:[NSNull null]]) {
            RKLogDebug(@"Did not find mappable relationship value keyPath '%@'", relationshipMapping.sourceKeyPath);
            
            // Optionally nil out the property
            if ([self.objectMapping setNilForMissingRelationships] && [self shouldSetValue:nil atKeyPath:relationshipMapping.destinationKeyPath]) {
                RKLogTrace(@"Setting nil for missing relationship value at keyPath '%@'", relationshipMapping.sourceKeyPath);
                [self.destinationObject setValue:nil forKey:relationshipMapping.destinationKeyPath];
            }
            
            continue;
        }
                
        if ([value isCollection]) {        
            // One to many relationship
            RKLogDebug(@"Mapping one to many relationship value at keyPath '%@' to '%@'", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath);
            appliedMappings = YES;
            
            destinationObject = [NSMutableArray arrayWithCapacity:[value count]];
            for (id nestedObject in value) {                
                id<RKObjectMappingDefinition> mapping = relationshipMapping.mapping;
                RKObjectMapping* objectMapping = nil;
                if ([mapping isKindOfClass:[RKDynamicObjectMapping class]]) {
                    objectMapping = [(RKDynamicObjectMapping*)mapping objectMappingForDictionary:nestedObject];
                    if (! objectMapping) {
                        RKLogDebug(@"Mapping %@ declined mapping for data %@: returned nil objectMapping", mapping, nestedObject);
                        continue;
                    }
                } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
                    objectMapping = (RKObjectMapping*)mapping;
                } else {
                    NSAssert(objectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
                }
                id mappedObject = [objectMapping mappableObjectForData:nestedObject];
                if ([self mapNestedObject:nestedObject toObject:mappedObject withRealtionshipMapping:relationshipMapping]) {
                    [destinationObject addObject:mappedObject];
                }
            }
            
            // Transform from NSSet <-> NSArray if necessary
            if (relationshipType && NO == [[destinationObject class] isSubclassOfClass:relationshipType])
            {
                destinationObject = [transform transformedValue:destinationObject ofClass:relationshipType error:nil];
            }
            
            // If the relationship has changed, set it
            if ([self shouldSetValue:destinationObject atKeyPath:relationshipMapping.destinationKeyPath]) {
                Class managedObjectClass = NSClassFromString(@"NSManagedObject");
                if (managedObjectClass && [self.destinationObject isKindOfClass:managedObjectClass]) {
                    RKLogTrace(@"Found a managedObject collection. About to apply value via mutable[Set|Array]ValueForKey");
                    if ([destinationObject isKindOfClass:[NSSet class]]) {
                        RKLogTrace(@"Mapped NSSet relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                        NSMutableSet* destinationSet = [self.destinationObject mutableSetValueForKey:relationshipMapping.destinationKeyPath];
                        [destinationSet setSet:destinationObject];
                    } else if ([destinationObject isKindOfClass:[NSArray class]]) {
                        RKLogTrace(@"Mapped NSArray relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                        NSMutableArray* destinationArray = [self.destinationObject mutableArrayValueForKey:relationshipMapping.destinationKeyPath];
                        [destinationArray setArray:destinationObject];
                    }
                } else {
                    RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
                    [self.destinationObject setValue:destinationObject forKey:relationshipMapping.destinationKeyPath];
                }
            }
        } else {
            // One to one relationship
            RKLogDebug(@"Mapping one to one relationship value at keyPath '%@' to '%@'", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath);            
            
            id<RKObjectMappingDefinition> mapping = relationshipMapping.mapping;
            RKObjectMapping* objectMapping = nil;
            if ([mapping isKindOfClass:[RKDynamicObjectMapping class]]) {
                objectMapping = [(RKDynamicObjectMapping*)mapping objectMappingForDictionary:value];
            } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
                objectMapping = (RKObjectMapping*)mapping;
            }
            NSAssert(objectMapping, @"Encountered unknown mapping type '%@'", NSStringFromClass([mapping class]));
            destinationObject = [objectMapping mappableObjectForData:value];
            if ([self mapNestedObject:value toObject:destinationObject withRealtionshipMapping:relationshipMapping]) {
                appliedMappings = YES;
            }
        }
        
        // If the relationship has changed, set it
        if ([self shouldSetValue:destinationObject atKeyPath:relationshipMapping.destinationKeyPath]) {
            RKLogTrace(@"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", relationshipMapping.sourceKeyPath, relationshipMapping.destinationKeyPath, destinationObject);
            [self.destinationObject setValue:destinationObject forKey:relationshipMapping.destinationKeyPath];
        }
        
        // Fail out if a validation error has occurred
        if (_validationError) {
            return NO;
        }
    }
    
    return appliedMappings;
}

- (void)applyNestedMappings {
    RKObjectAttributeMapping* attributeMapping = [self.objectMapping mappingForKeyPath:RKObjectMappingNestingAttributeKeyName];
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

- (BOOL)performMapping:(NSError**)error {
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

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectMappingOperation for '%@' object. Mapping values from object %@ to object %@ with object mapping %@",
            NSStringFromClass([self.destinationObject class]), self.sourceObject, self.destinationObject, self.objectMapping];
}

@end
