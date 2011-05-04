//
//  RKObjectMappingOperation.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMappingOperation.h"
#import "Errors.h"
#import "RKObjectPropertyInspector.h"
#import "Logging.h"

@implementation RKObjectMappingOperation

@synthesize sourceObject = _sourceObject;
@synthesize destinationObject = _destinationObject;
@synthesize keyPath = _keyPath;
@synthesize objectMapping = _objectMapping;
@synthesize delegate = _delegate;

- (id)initWithSourceObject:(id)sourceObject destinationObject:(id)destinationObject keyPath:(NSString*)keyPath objectMapping:(RKObjectMapping*)objectMapping {
    NSAssert(sourceObject != nil, @"Cannot perform a mapping operation without a sourceObject object");
    NSAssert(destinationObject != nil, @"Cannot perform a mapping operation without a destinationObject");
    NSAssert(keyPath != nil, @"Cannot perform a mapping operation without a keyPath context");
    NSAssert(objectMapping != nil, @"Cannot perform a mapping operation without an object mapping to apply");
    
    self = [super init];
    if (self) {
        _sourceObject = [sourceObject retain];
        _destinationObject = [destinationObject retain];
        _keyPath = [keyPath retain];
        _objectMapping = [objectMapping retain];
    }
    
    return self;
}

- (void)dealloc {
    [_sourceObject release];
    [_destinationObject release];
    [_keyPath release];
    [_objectMapping release];
    
    [super dealloc];
}

- (NSString*)objectClassName {
    return NSStringFromClass([self.destinationObject class]);
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
    }
    
    return nil;
}

// Return YES if we mapped any attributes
- (BOOL)applyAttributeMappings {
    BOOL appliedMappings = NO;
    
    for (RKObjectAttributeMapping* attributeMapping in self.objectMapping.mappings) {
        // TODO: Catch exceptions here... valueForUndefinedKey
        // TODO: Handle nil's and NSNull
        id value = [self.sourceObject valueForKeyPath:attributeMapping.sourceKeyPath];
        if (value) {
            appliedMappings = YES;
            [self.delegate objectMappingOperation:self didFindMapping:attributeMapping forKeyPath:attributeMapping.sourceKeyPath];
            // TODO: didFindMappableValue:atKeyPath:
            // TODO: Handle relationships and collections by evaluating the type of the elementMapping???
            // didSetValue:forKeyPath:fromKeyPath:
            // Inspect the property type to handle any value transformations
            Class type = [[RKObjectPropertyInspector sharedInspector] typeForProperty:attributeMapping.destinationKeyPath ofClass:[self.destinationObject class]];
            if (type && NO == [[value class] isSubclassOfClass:type]) {
                value = [self transformValue:value atKeyPath:attributeMapping.sourceKeyPath toType:type];
            }
            [self.destinationObject setValue:value forKey:attributeMapping.destinationKeyPath];
            [self.delegate objectMappingOperation:self didSetValue:value forKeyPath:attributeMapping.destinationKeyPath usingMapping:attributeMapping];
            // didMapValue:fromValue:usingMapping
        } else {
            [self.delegate objectMappingOperation:self didNotFindMappingForKeyPath:attributeMapping.sourceKeyPath];
            // TODO: didNotFindMappableValue:forKeyPath:
        }
    }
    
    return appliedMappings;
}

- (BOOL)applyRelationshipMappings {
    return NO;
}

- (id)performMappingWithError:(NSError**)error {
    BOOL mappedAttributes = [self applyAttributeMappings];
    BOOL mappedRelationships = [self applyRelationshipMappings];
    
    // Return the destination object if we were successful
    if (mappedAttributes || mappedRelationships) {
        return self.destinationObject;
    } else {
        // TODO: No error message...
        NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"", NSLocalizedDescriptionKey,
                                  @"RKObjectMapperKeyPath", self.keyPath,
                                  nil];
        int RKObjectMapperErrorUnmappableContent = 2; // TODO: Temporary
        NSError* unmappableError = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectMapperErrorUnmappableContent userInfo:userInfo];        
        [self.delegate objectMappingOperation:self didFailWithError:unmappableError];
        if (error) {
            *error = unmappableError;
        }
        return nil;
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"RKObjectMappingOperation for '%@' object at 'keyPath': %@. Mapping values from object %@ to object %@ with object mapping %@",
            [self objectClassName], self.keyPath, self.sourceObject, self.destinationObject];
}

@end
