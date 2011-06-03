//
//  RKObjectMappingOperation.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <objc/message.h>
#import "RKObjectMappingOperation.h"
#import "RKObjectMapperError.h"
#import "RKObjectPropertyInspector.h"
#import "RKObjectRelationshipMapping.h"
#import "RKObjectMapper.h"
#import "../Support/Errors.h"
#import "../Support/Logging.h"

@implementation RKObjectMappingOperation

@synthesize sourceObject = _sourceObject;
@synthesize destinationObject = _destinationObject;
@synthesize objectMapping = _objectMapping;
@synthesize delegate = _delegate;
@synthesize objectFactory = _objectFactory;

+ (RKObjectMappingOperation*)mappingOperationFromObject:(id)sourceObject toObject:(id)destinationObject withObjectMapping:(RKObjectMapping*)objectMapping {
    return [[[self alloc] initWithSourceObject:sourceObject destinationObject:destinationObject objectMapping:objectMapping] autorelease];
}

- (id)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject objectMapping:(RKObjectMapping*)objectMapping {
    NSAssert(sourceObject != nil, @"Cannot perform a mapping operation without a sourceObject object");
    NSAssert(destinationObject != nil, @"Cannot perform a mapping operation without a destinationObject");
    NSAssert(objectMapping != nil, @"Cannot perform a mapping operation without an object mapping to apply");
    
    self = [super init];
    if (self) {
        _sourceObject = [sourceObject retain];
        _destinationObject = [destinationObject retain];
        _objectMapping = [objectMapping retain];
    }
    
    return self;
}

- (void)dealloc {
    [_sourceObject release];
    [_destinationObject release];
    [_objectMapping release];
    
    [super dealloc];
}

- (NSDate*)parseDateFromString:(NSString*)string {
    RKLOG_MAPPING(RKLogLevelDebug, @"Transforming string value '%@' to NSDate...", string);
    
	NSDate* date = nil;
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone localTimeZone];
	for (NSString* formatString in self.objectMapping.dateFormatStrings) {
		[formatter setDateFormat:formatString];
		date = [formatter dateFromString:string];
		if (date) {
			break;
		}
	}
	
	[formatter release];
	return date;
}

- (id)transformValue:(id)value atKeyPath:keyPath toType:(Class)destinationType {
    RKLOG_MAPPING(RKLogLevelDebug, @"Found transformable value at keyPath '%@'. Transforming from type '%@' to '%@'", keyPath, NSStringFromClass([value class]), NSStringFromClass(destinationType));
    Class sourceType = [value class];
    
    if ([sourceType isSubclassOfClass:[NSString class]]) {
        if ([destinationType isSubclassOfClass:[NSDate class]]) {
            // String -> Date
            return [self parseDateFromString:(NSString*)value];
        } else if ([destinationType isSubclassOfClass:[NSURL class]]) {
            // String -> URL
            return [NSURL URLWithString:(NSString*)value];
        } else if ([destinationType isSubclassOfClass:[NSDecimalNumber class]]) {
            // String -> Decimal Number
            return [NSDecimalNumber decimalNumberWithString:(NSString*)value];
        } else if ([destinationType isSubclassOfClass:[NSNumber class]]) {
            // String -> Number
            NSString* lowercasedString = [(NSString*)value lowercaseString];
            if ([lowercasedString isEqualToString:@"true"] || [lowercasedString isEqualToString:@"false"]) {
                // Handle booleans encoded as Strings
                return [NSNumber numberWithBool:[lowercasedString isEqualToString:@"true"]];
            } else {
                return [NSNumber numberWithDouble:[(NSString*)value doubleValue]];
            }
        }
    } else if (value == [NSNull null] || [value isEqual:[NSNull null]]) {
        // Transform NSNull -> nil for simplicity
        return nil;
    } else if ([sourceType isSubclassOfClass:[NSSet class]]) {
        // Set -> Array
        if ([destinationType isSubclassOfClass:[NSArray class]]) {
            return [(NSSet*)value allObjects];
        }
    } else if ([sourceType isSubclassOfClass:[NSArray class]]) {
        // Array -> Set
        if ([destinationType isSubclassOfClass:[NSSet class]]) {
            return [NSSet setWithArray:value];
        }
    }
    
    RKLOG_MAPPING(RKLogLevelWarning, @"Failed transformation of value at keyPath '%@'. No strategy for transforming from '%@' to '%@'", NSStringFromClass([value class]), NSStringFromClass(destinationType));
    
    return nil;
}

- (BOOL)isValue:(id)sourceValue equalToValue:(id)destinationValue {
    NSAssert(sourceValue, @"Expected sourceValue not to be nil");
    NSAssert(destinationValue, @"Expected destinationValue not to be nil");
    
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
        return YES;
	}
    
    BOOL isEqual = [self isValue:value equalToValue:currentValue];
    return !isEqual;
}

// Return YES if we mapped any attributes
- (BOOL)applyAttributeMappings {
    BOOL appliedMappings = NO;
    
    for (RKObjectAttributeMapping* attributeMapping in self.objectMapping.attributeMappings) {
        id value = nil;
        if ([attributeMapping.sourceKeyPath isEqualToString:@""]) {
            value = self.sourceObject;
        } else {
            value = [self.sourceObject valueForKeyPath:attributeMapping.sourceKeyPath];
        }
        if (value) {
            appliedMappings = YES;
            if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didFindMapping:forKeyPath:)]) {
                [self.delegate objectMappingOperation:self didFindMapping:attributeMapping forKeyPath:attributeMapping.sourceKeyPath];
            }
            RKLOG_MAPPING(RKLogLevelInfo, @"Mapping attribute value keyPath '%@' to '%@'", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath);
            
            // Inspect the property type to handle any value transformations
            Class type = [[RKObjectPropertyInspector sharedInspector] typeForProperty:attributeMapping.destinationKeyPath ofClass:[self.destinationObject class]];
            if (type && NO == [[value class] isSubclassOfClass:type]) {
                value = [self transformValue:value atKeyPath:attributeMapping.sourceKeyPath toType:type];
            }
            
            // Ensure that the value is different
            if ([self shouldSetValue:value atKeyPath:attributeMapping.destinationKeyPath]) {
                [self.destinationObject setValue:value forKey:attributeMapping.destinationKeyPath];
                if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didSetValue:forKeyPath:usingMapping:)]) {
                    [self.delegate objectMappingOperation:self didSetValue:value forKeyPath:attributeMapping.destinationKeyPath usingMapping:attributeMapping];
                }
                RKLOG_MAPPING(RKLogLevelDebug, @"Mapped attribute value from keyPath '%@' to '%@'. Value: %@", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath, value);
            } else {
                RKLOG_MAPPING(RKLogLevelDebug, @"Skipped mapping of attribute value from keyPath '%@ to keyPath '%@' -- value is unchanged (%@)", attributeMapping.sourceKeyPath, attributeMapping.destinationKeyPath, value);
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didNotFindMappingForKeyPath:)]) {
                [self.delegate objectMappingOperation:self didNotFindMappingForKeyPath:attributeMapping.sourceKeyPath];
            }
            RKLOG_MAPPING(RKLogLevelInfo, @"Did not find mappable attribute value keyPath '%@'", attributeMapping.sourceKeyPath);
            
            // Optionally set nil for missing values
            if ([self.objectMapping setNilForMissingAttributes]) {
                [self.destinationObject setValue:nil forKey:attributeMapping.destinationKeyPath];
                RKLOG_MAPPING(RKLogLevelInfo, @"Setting nil for missing attribute value at keyPath '%@'", attributeMapping.sourceKeyPath);
            }
        }
    }
    
    return appliedMappings;
}

- (BOOL)isValueACollection:(id)value {
    return ([value isKindOfClass:[NSSet class]] || [value isKindOfClass:[NSArray class]]);
}

- (BOOL)mapNestedObject:(id)anObject toObject:(id)anotherObject withMapping:(RKObjectRelationshipMapping*)mapping {
    NSError* error = nil;
    
    RKObjectMappingOperation* subOperation = [RKObjectMappingOperation mappingOperationFromObject:anObject toObject:anotherObject withObjectMapping:mapping.objectMapping];
    subOperation.delegate = self.delegate;
    subOperation.objectFactory = self.objectFactory;
    if (NO == [subOperation performMapping:&error]) {
        RKLOG_MAPPING(RKLogLevelWarning, @"WARNING: Failed mapping nested object: %@", [error localizedDescription]);
    }
    
    return YES;
}

- (BOOL)applyRelationshipMappings {
    BOOL appliedMappings = NO;
    id destinationObject = nil;
    
    for (RKObjectRelationshipMapping* mapping in self.objectMapping.relationshipMappings) {
        id value = [self.sourceObject valueForKeyPath:mapping.sourceKeyPath];
        
        if (value == nil || value == [NSNull null] || [value isEqual:[NSNull null]]) {
            RKLOG_MAPPING(RKLogLevelInfo, @"Did not find mappable relationship value keyPath '%@'", mapping.sourceKeyPath);
            
            // Optionally nil out the property
            if ([self.objectMapping setNilForMissingRelationships] && [self shouldSetValue:nil atKeyPath:mapping.destinationKeyPath]) {
                [self.destinationObject setValue:nil forKey:mapping.destinationKeyPath];
                
                RKLOG_MAPPING(RKLogLevelInfo, @"Setting nil for missing relationship value at keyPath '%@'", mapping.sourceKeyPath);
            }
            
            continue;
        }
                
        if ([self isValueACollection:value]) {
            // One to many relationship
            RKLOG_MAPPING(RKLogLevelInfo, @"Mapping one to many relationship value at keyPath '%@' to '%@'", mapping.sourceKeyPath, mapping.destinationKeyPath);
            appliedMappings = YES;
            
            destinationObject = [NSMutableArray arrayWithCapacity:[value count]];
            for (id nestedObject in value) {
                id mappedObject = [self.objectFactory objectWithMapping:mapping.objectMapping andData:nestedObject];
                if ([self mapNestedObject:nestedObject toObject:mappedObject withMapping:mapping]) {
                    [destinationObject addObject:mappedObject];
                }
            }
            
            // Transform from NSSet <-> NSArray if necessary
            Class type = [[RKObjectPropertyInspector sharedInspector] typeForProperty:mapping.destinationKeyPath ofClass:[self.destinationObject class]];
            if (type && NO == [[destinationObject class] isSubclassOfClass:type]) {
                destinationObject = [self transformValue:destinationObject atKeyPath:mapping.sourceKeyPath toType:type];
            }
        } else {
            // One to one relationship
            RKLOG_MAPPING(RKLogLevelInfo, @"Mapping one to one relationship value at keyPath '%@' to '%@'", mapping.sourceKeyPath, mapping.destinationKeyPath);            
            
            destinationObject = [self.objectFactory objectWithMapping:mapping.objectMapping andData:value];
            if ([self mapNestedObject:value toObject:destinationObject withMapping:mapping]) {
                appliedMappings = YES;
            }
        }
        
        // If the relationship has changed, set it
        if ([self shouldSetValue:destinationObject atKeyPath:mapping.destinationKeyPath]) {
            [self.destinationObject setValue:destinationObject forKey:mapping.destinationKeyPath];
            RKLOG_MAPPING(RKLogLevelDebug, @"Mapped relationship object from keyPath '%@' to '%@'. Value: %@", mapping.sourceKeyPath, mapping.destinationKeyPath, destinationObject);
        }
    }
    
    return appliedMappings;
}

- (BOOL)performMapping:(NSError**)error {
    RKLOG_START_BLOCK(@"Starting mapping operation...");
    BOOL mappedAttributes = [self applyAttributeMappings];
    BOOL mappedRelationships = [self applyRelationshipMappings];
    if (mappedAttributes || mappedRelationships) {
        RKLOG_END_BLOCK();
        return YES;
    } else {
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"No mappable attributes or relationships found.", NSLocalizedDescriptionKey,
                                  nil];
        NSError* unmappableError = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectMapperErrorUnmappableContent userInfo:userInfo];
        if ([self.delegate respondsToSelector:@selector(objectMappingOperation:didFailWithError:)]) {
            [self.delegate objectMappingOperation:self didFailWithError:unmappableError];
        }
        if (error) {
            *error = unmappableError;
        }
        
        RKLOG_END_BLOCK();
        return NO;
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectMappingOperation for '%@' object. Mapping values from object %@ to object %@ with object mapping %@",
            NSStringFromClass([self.destinationObject class]), self.sourceObject, self.destinationObject, self.objectMapping];
}

@end
