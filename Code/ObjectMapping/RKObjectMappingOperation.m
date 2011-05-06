//
//  RKObjectMappingOperation.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <objc/message.h>
#import "RKObjectMappingOperation.h"
#import "Errors.h"
#import "RKObjectPropertyInspector.h"
#import "Logging.h"
#import "RKObjectRelationshipMapping.h"

@implementation RKObjectMappingOperation

@synthesize sourceObject = _sourceObject;
@synthesize destinationObject = _destinationObject;
@synthesize objectMapping = _objectMapping;
@synthesize delegate = _delegate;

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

// TODO: Figure out where these live. Maybe they go on the object mapping?
// TODO: Move these into constants?
- (NSArray*)dateFormats {
    return [NSArray arrayWithObjects:@"yyyy-MM-dd'T'HH:mm:ss'Z'", @"MM/dd/yyyy", nil];
}

- (NSDate*)parseDateFromString:(NSString*)string {
    RKLOG_MAPPING(RKLogLevelDebug, @"Transforming string value '%@' to NSDate...");
    
	NSDate* date = nil;
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.timeZone = [NSTimeZone localTimeZone];
	for (NSString* formatString in self.dateFormats) {
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
    RKLOG_MAPPING(RKLogLevelInfo, @"Found transformable value at keyPath '%@'. Transforming from type '%@' to '%@'", NSStringFromClass([value class]), NSStringFromClass(destinationType));
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
    
    return nil;
}

- (BOOL)isValue:(id)sourceValue equalToValue:(id)destinationValue {
    NSAssert(sourceValue, @"Expected sourceValue not to be nil");
    NSAssert(destinationValue, @"Expected destinationValue not to be nil");
    // TODO: Disabled, comparison of mutable to immutable arrays fails the assertion
    //NSAssert2([destinationValue isKindOfClass:[sourceValue class]], @"Expected sourceValue and destinationValue to be of the same type. %@ != %@", NSStringFromClass([sourceValue class]), NSStringFromClass([destinationValue class]));
    
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
    // TODO: Logging...
    
    id currentValue = [self.destinationObject valueForKey:keyPath];
    if (currentValue == [NSNull null] || [currentValue isEqual:[NSNull null]]) {
        currentValue = nil;
    }
    
	if (nil == currentValue && nil == value) {
		// Both are nil
        // TODO: Debug logging...
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
        // TODO: Catch exceptions here... valueForUndefinedKey
        id value = [self.sourceObject valueForKeyPath:attributeMapping.sourceKeyPath];
        if (value) {
            appliedMappings = YES;
            [self.delegate objectMappingOperation:self didFindMapping:attributeMapping forKeyPath:attributeMapping.sourceKeyPath];
            
            // Inspect the property type to handle any value transformations
            Class type = [[RKObjectPropertyInspector sharedInspector] typeForProperty:attributeMapping.destinationKeyPath ofClass:[self.destinationObject class]];
            if (type && NO == [[value class] isSubclassOfClass:type]) {
                value = [self transformValue:value atKeyPath:attributeMapping.sourceKeyPath toType:type];
            }
            
            // Ensure that the value is different
            if ([self shouldSetValue:value atKeyPath:attributeMapping.destinationKeyPath]) {
                [self.destinationObject setValue:value forKey:attributeMapping.destinationKeyPath];
                [self.delegate objectMappingOperation:self didSetValue:value forKeyPath:attributeMapping.destinationKeyPath usingMapping:attributeMapping];
                // didMapValue:fromValue:usingMapping
            } else {
                // TODO: Debug log that it was skipped
            }
        } else {
            [self.delegate objectMappingOperation:self didNotFindMappingForKeyPath:attributeMapping.sourceKeyPath];
            // TODO: didNotFindMappableValue:forKeyPath:
            
            // Optionally set nil for missing values
            if ([self.objectMapping shouldSetNilForMissingAttributes]) {
                [self.destinationObject setValue:nil forKey:attributeMapping.destinationKeyPath];
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
    if (NO == [subOperation performMapping:&error]) {
        // TODO: Log the error. Warning?
    }
    
    return YES;
}

- (BOOL)applyRelationshipMappings {
    BOOL appliedMappings = NO;
    id destinationObject = nil;
    
    for (RKObjectRelationshipMapping* mapping in self.objectMapping.relationshipMappings) {
        id value = [self.sourceObject valueForKeyPath:mapping.sourceKeyPath];
        if (value == nil || value == [NSNull null] || [value isEqual:[NSNull null]]) {
            // Optionally nil out the property
            if ([self.objectMapping shouldSetNilForMissingRelationships] && [self shouldSetValue:nil atKeyPath:mapping.destinationKeyPath]) {
                [self.destinationObject setValue:nil forKey:mapping.destinationKeyPath];
            }
            
            // TODO: Log messages here...
            continue;
        }
                
        if ([self isValueACollection:value]) {
            // One to many relationship
            destinationObject = [NSMutableArray arrayWithCapacity:[value count]];
            for (id nestedObject in value) {
                id mappedObject = [mapping.objectMapping.objectClass new];
                if ([self mapNestedObject:nestedObject toObject:mappedObject withMapping:mapping]) {
                    appliedMappings = YES;
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
            destinationObject = [[mapping.objectMapping.objectClass new] autorelease];
            if ([self mapNestedObject:value toObject:destinationObject withMapping:mapping]) {
                appliedMappings = YES;
                // TODO: Logging
            }
        }
        
        // If the relationship has changed, set it
        if ([self shouldSetValue:destinationObject atKeyPath:mapping.destinationKeyPath]) {
            [self.destinationObject setValue:destinationObject forKey:mapping.destinationKeyPath];
        }
    }
    
    return appliedMappings;
}

- (BOOL)performMapping:(NSError**)error {
    BOOL mappedAttributes = [self applyAttributeMappings];
    BOOL mappedRelationships = [self applyRelationshipMappings];
    if (mappedAttributes || mappedRelationships) {
        return YES;
    } else {
        // TODO: Improve error message...
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"Unable to identify any mappable content", NSLocalizedDescriptionKey,
                                  nil];
        int RKObjectMapperErrorUnmappableContent = 2; // TODO: Temporary
        NSError* unmappableError = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectMapperErrorUnmappableContent userInfo:userInfo];        
        [self.delegate objectMappingOperation:self didFailWithError:unmappableError];
        if (error) {
            *error = unmappableError;
        }
        
        return NO;
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectMappingOperation for '%@' object. Mapping values from object %@ to object %@ with object mapping %@",
            NSStringFromClass([self.destinationObject class]), self.sourceObject, self.destinationObject, self.objectMapping];
}

@end
