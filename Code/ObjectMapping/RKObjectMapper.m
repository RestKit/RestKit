//
//  RKObjectMapper.m
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <objc/message.h>

#import "../CoreData/CoreData.h"
#import "RKObjectManager.h"

#import "RKObjectMapper.h"
#import "NSDictionary+RKAdditions.h"
#import "RKJSONParser.h"
#import "RKXMLParser.h"
#import "Errors.h"

// Default format string for date and time objects from Rails
// TODO: Rails specifics should probably move elsewhere...
static const NSString* kRKModelMapperRailsDateTimeFormatString = @"yyyy-MM-dd'T'HH:mm:ss'Z'"; // 2009-08-08T17:23:59Z
static const NSString* kRKModelMapperRailsDateFormatString = @"MM/dd/yyyy";

@interface RKObjectMapper (Private)

- (id)parseString:(NSString*)string;

- (Class)typeClassForProperty:(NSString*)property ofClass:(Class)class;
- (NSDictionary*)elementToPropertyMappingsForModel:(id)model;

- (id)findOrCreateInstanceOfModelClass:(Class)class fromElements:(NSDictionary*)elements;
- (id)createOrUpdateInstanceOfModelClass:(Class)class fromElements:(NSDictionary*)elements;

- (void)updateModel:(id)model ifNewPropertyValue:(id)propertyValue forPropertyNamed:(NSString*)propertyName; // Rename!
- (void)updateModel:(id)model fromElements:(NSDictionary*)elements;
- (void)setPropertiesOfModel:(id)model fromElements:(NSDictionary*)elements;
- (void)setRelationshipsOfModel:(id)object fromElements:(NSDictionary*)elements;

- (NSDate*)parseDateFromString:(NSString*)string;
- (NSDate*)dateInLocalTime:(NSDate*)date;

@end

@implementation RKObjectMapper

@synthesize format = _format;
@synthesize missingElementMappingPolicy = _missingElementMappingPolicy;
@synthesize dateFormats = _dateFormats;
@synthesize remoteTimeZone = _remoteTimeZone;
@synthesize localTimeZone = _localTimeZone;
@synthesize errorsKeyPath = _errorsKeyPath;
@synthesize errorsConcatenationString = _errorsConcatenationString;

///////////////////////////////////////////////////////////////////////////////
// public

- (id)init {
	if ((self = [super init])) {
		_elementToClassMappings = [[NSMutableDictionary alloc] init];
		_format = RKMappingFormatJSON;
		_missingElementMappingPolicy = RKIgnoreMissingElementMappingPolicy;
		_inspector = [[RKObjectPropertyInspector alloc] init];
		self.dateFormats = [NSArray arrayWithObjects:kRKModelMapperRailsDateTimeFormatString, kRKModelMapperRailsDateFormatString, nil];
		self.remoteTimeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
		self.localTimeZone = [NSTimeZone localTimeZone];
		self.errorsKeyPath = @"errors";
		self.errorsConcatenationString = @", ";
	}
	return self;
}

- (void)dealloc {
	[_elementToClassMappings release];
	[_inspector release];
	[_dateFormats release];
	[_errorsKeyPath release];
	[_errorsConcatenationString release];
	[super dealloc];
}

- (void)registerClass:(Class<RKObjectMappable>)aClass forElementNamed:(NSString*)elementName {
	[_elementToClassMappings setObject:aClass forKey:elementName];
}

- (void)setFormat:(RKMappingFormat)format {
	_format = format;
}

///////////////////////////////////////////////////////////////////////////////
// Mapping from a string

- (id)parseString:(NSString*)string {
    Class parserClass;
    NSString* className = nil;
    NSObject<RKParser>* parser = nil;
    
    if (_format == RKMappingFormatJSON) {
        className = @"RKJSONParser";
    } else if (_format == RKMappingFormatXML) {
        className = @"RKXMLParser";
    }
    
    parserClass = NSClassFromString(className);
    if (nil == parserClass) {
        [NSException raise:@"Unable to find an appropriate parser." 
                    format:@"The object mapper attempted to process a payload via the '%@' parser, but it was not found.", className];
    }
	
    parser = [[parserClass alloc] init];
	id result = nil;
	@try {
		result = [parser objectFromString:string];
	}
	@catch (NSException* e) {
		NSLog(@"[RestKit] RKObjectMapper:parseString: Exception (%@) parsing error from string: %@", [e reason], string);
	}
    [parser release];
    
	return result;
}

- (NSError*)parseErrorFromString:(NSString*)string {
	NSString* errorMessage = [[[self parseString:string] valueForKeyPath:_errorsKeyPath] componentsJoinedByString:_errorsConcatenationString];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  errorMessage, NSLocalizedDescriptionKey,
							  nil];
	NSError *error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectLoaderRemoteSystemError userInfo:userInfo];
	
	return error;
}

// Primary entry point for RKObjectLoader
- (id)mapFromString:(NSString*)string toClass:(Class<RKObjectMappable>)class keyPath:(NSString*)keyPath {
	id object = [self parseString:string];
	if (keyPath) {
		object = [object valueForKeyPath:keyPath];
	}
  
	if ([object isKindOfClass:[NSDictionary class]]) {
        if (class) {
            return [self mapObjectFromDictionary:(NSDictionary*)object toClass:class];
        } else {
            return [self mapObjectFromDictionary:(NSDictionary*)object];
        }
	} else if ([object isKindOfClass:[NSArray class]]) {
		if (class) {
			return [self mapObjectsFromArrayOfDictionaries:(NSArray*)object toClass:class];
		} else {
			return [self mapObjectsFromArrayOfDictionaries:(NSArray*)object];
		}
	} else if (nil == object) {
		NSLog(@"[RestKit] RKModelMapper: mapObject:fromString: attempted to map from a nil payload. Skipping...");
		return nil;
	} else {
		[NSException raise:@"Unable to map from requested string" 
					format:@"The object was deserialized into a %@. A dictionary or array of dictionaries was expected.", [object class]];
		return nil;
	}
}

- (id)mapFromString:(NSString*)string {
	return [self mapFromString:string toClass:nil keyPath:nil];
}

- (void)mapObject:(NSObject<RKObjectMappable>*)model fromString:(NSString*)string {
	id object = [self parseString:string];
	if ([object isKindOfClass:[NSDictionary class]]) {
		[self mapObject:model fromDictionary:object];
	} else if (nil == object) {
		NSLog(@"[RestKit] RKModelMapper: mapObject:fromString: attempted to map from a nil payload. Skipping...");
		return;
	} else {
		[NSException raise:@"Unable to map from requested string"
					format:@"The object was serialized into a %@. A dictionary of elements was expected. (Object: %@) [Payload: %@]", [object class], object, string];
	}
}

///////////////////////////////////////////////////////////////////////////////
// Mapping from objects

- (void)mapObject:(NSObject<RKObjectMappable>*)model fromDictionary:(NSDictionary*)dictionary {
	Class class = [model class];
	
	NSArray* elementNames = [_elementToClassMappings allKeysForObject:class];
	if ([elementNames count] == 0) {
		if ([model conformsToProtocol:@protocol(RKObjectMappable)]) {
			[self updateModel:model fromElements:dictionary];
		} else {
			[NSException raise:@"Unable to map from requested dictionary"
						format:@"There was no mappable element found for objects of type %@", class];
		}
	} else {
		for (NSString* elementName in elementNames) {
			if ([[dictionary allKeys] containsObject:elementName]) {
				NSDictionary* elements = [dictionary objectForKey:elementName];
				[self updateModel:model fromElements:elements];
				return;
			}
		}
		// If the dictionary is not namespaced, attempt mapping its properties directly...
		[self updateModel:model fromElements:dictionary];
	}
}

- (NSObject<RKObjectMappable>*)mapObjectFromDictionary:(NSDictionary*)dictionary toClass:(Class)class {
	return [self createOrUpdateInstanceOfModelClass:class fromElements:dictionary];
}

// Lookup an object type using the element to class mappings and map its attributes
// Expects an object of the form {"registered_type": {"attribute1": "value", "attribute2": "value"}
- (NSObject<RKObjectMappable>*)mapObjectFromDictionary:(NSDictionary*)dictionary {
  // TODO: Makes assumptions about the structure of the JSON...
	NSString* elementName = [[dictionary allKeys] objectAtIndex:0];
	Class class = [_elementToClassMappings objectForKey:elementName];
	id elements = [dictionary objectForKey:elementName];
	
    // Support case where elements is an Array of objects
    id model = nil;
    if ([elements isKindOfClass:[NSDictionary class]]) {
        model = [self findOrCreateInstanceOfModelClass:class fromElements:elements];
        [self updateModel:model fromElements:elements];        
    } else if ([elements isKindOfClass:[NSArray class]]) {
        model = [self mapObjectsFromArrayOfDictionaries:elements toClass:class];
    } else {
        // TODO: Do we want to blow up or log???
        NSLog(@"Unable to determine how to map object: %@", elements);
    }
    
	return model;
}

- (NSArray*)mapObjectsFromArrayOfDictionaries:(NSArray*)array {
	NSMutableArray* objects = [NSMutableArray array];
	for (NSDictionary* dictionary in array) {
		if (![dictionary isKindOfClass:[NSNull class]]) {
			// TODO: Makes assumptions about the structure of the JSON...
			NSString* elementName = [[dictionary allKeys] objectAtIndex:0];
			Class class = [_elementToClassMappings objectForKey:elementName];
			NSAssert(class != nil, @"Unable to perform object mapping without a destination class");
			NSDictionary* elements = [dictionary objectForKey:elementName];
			id object = [self createOrUpdateInstanceOfModelClass:class fromElements:elements];
			[objects addObject:object];
		}
	}
	
	return (NSArray*)objects;
}

- (NSArray*)mapObjectsFromArrayOfDictionaries:(NSArray*)array toClass:(Class<RKObjectMappable>)class {
	NSMutableArray* objects = [NSMutableArray array];
	for (NSDictionary* dictionary in array) {
		if (![dictionary isKindOfClass:[NSNull class]]) {
			id object = [self createOrUpdateInstanceOfModelClass:class fromElements:dictionary];
			[objects addObject:object];
		}
	}
	
	return (NSArray*)objects;
}

///////////////////////////////////////////////////////////////////////////////
// Utility Methods

- (Class)typeClassForProperty:(NSString*)property ofClass:(Class)class {
	return [[_inspector propertyNamesAndTypesForClass:class] objectForKey:property];
}

- (NSDictionary*)elementToPropertyMappingsForModel:(id)model {
	return [[model class] elementToPropertyMappings];
}

///////////////////////////////////////////////////////////////////////////////
// Persistent Instance Finders

// TODO: This version does not update properties. Should probably be realigned.
- (NSObject<RKObjectMappable>*)findOrCreateInstanceOfModelClass:(Class)class fromElements:(NSDictionary*)elements {
	id object = nil;
    Class managedObjectClass = NSClassFromString(@"RKManagedObject");
	if (managedObjectClass && [class isSubclassOfClass:managedObjectClass]) {
		NSString* primaryKeyElement = [class performSelector:@selector(primaryKeyElement)];
		id primaryKeyValue = [elements objectForKey:primaryKeyElement];
		object = [[[RKObjectManager sharedManager] objectStore] findOrCreateInstanceOfManagedObject:class
                                                                                withPrimaryKeyValue:primaryKeyValue];
	}
	// instantiate if object is nil
	if (object == nil) {
        if ([class conformsToProtocol:@protocol(RKObjectMappable)] && [class respondsToSelector:@selector(object)]) {
            object = [class object];
        } else {
            // Allow non-RKObjectMappable objecs to pass through to alloc/init. Do we need this?
            object = [[[class alloc] init] autorelease];
        }
	}
	
	return object;
}

- (NSObject<RKObjectMappable>*)createOrUpdateInstanceOfModelClass:(Class<RKObjectMappable>)class fromElements:(NSDictionary*)elements {
	id model = [self findOrCreateInstanceOfModelClass:class fromElements:elements];
	[self updateModel:model fromElements:elements];
	return model;
}

///////////////////////////////////////////////////////////////////////////////
// Property & Relationship Manipulation

- (void)updateModel:(NSObject<RKObjectMappable>*)model ifNewPropertyValue:(id)propertyValue forPropertyNamed:(NSString*)propertyName {
	id currentValue = [model valueForKey:propertyName];
	if (nil == currentValue && nil == propertyValue) {
		// Don't set the property, both are nil
	} else if (nil == propertyValue || [propertyValue isKindOfClass:[NSNull class]]) {
		// Clear out the value to reset it
		[model setValue:nil forKey:propertyName];
	} else if (currentValue == nil || [currentValue isKindOfClass:[NSNull class]]) {
		// Existing value was nil, just set the property and be happy
		[model setValue:propertyValue forKey:propertyName];
	} else {
		SEL comparisonSelector;
		if ([propertyValue isKindOfClass:[NSString class]]) {
			comparisonSelector = @selector(isEqualToString:);
		} else if ([propertyValue isKindOfClass:[NSNumber class]]) {
			comparisonSelector = @selector(isEqualToNumber:);
		} else if ([propertyValue isKindOfClass:[NSDate class]]) {
			comparisonSelector = @selector(isEqualToDate:);
		} else if ([propertyValue isKindOfClass:[NSArray class]]) {
			comparisonSelector = @selector(isEqualToArray:);
		} else if ([propertyValue isKindOfClass:[NSDictionary class]]) {
			comparisonSelector = @selector(isEqualToDictionary:);
		} else {
			[NSException raise:@"NoComparisonSelectorFound" format:@"You need a comparison selector for %@ (%@)", propertyName, [propertyValue class]];
		}
		
		// Comparison magic using function pointers. See this page for details: http://www.red-sweater.com/blog/320/abusing-objective-c-with-class
		// Original code courtesy of Greg Parker
		// This is necessary because isEqualToNumber will return negative integer values that aren't coercable directly to BOOL's without help [sbw]
		BOOL (*ComparisonSender)(id, SEL, id) = (BOOL (*)(id, SEL, id)) objc_msgSend;		
		BOOL areEqual = ComparisonSender(currentValue, comparisonSelector, propertyValue);
		
		if (NO == areEqual) {
			[model setValue:propertyValue forKey:propertyName];
		}
	}
}

- (void)setPropertiesOfModel:(NSObject<RKObjectMappable>*)model fromElements:(NSDictionary*)elements {
	NSDictionary* elementToPropertyMappings = [self elementToPropertyMappingsForModel:model];
	for (NSString* elementKeyPath in elementToPropertyMappings) {		
		id elementValue = nil;
		BOOL setValue = YES;
		
		@try {
			elementValue = [elements valueForKeyPath:elementKeyPath];
		}
		@catch (NSException * e) {
			NSLog(@"[RestKit] RKModelMapper: Unable to find element at keyPath %@ in elements dictionary for %@. Skipping...", elementKeyPath, [model class]);
			setValue = NO;
		}
		
		// nil is returned when the collection does not contain the element
		if (nil == elementValue) {
			setValue = (_missingElementMappingPolicy == RKSetNilForMissingElementMappingPolicy);
		}
		
		if (setValue) {
			id propertyValue = elementValue;
			NSString* propertyName = [elementToPropertyMappings objectForKey:elementKeyPath];
			Class class = [self typeClassForProperty:propertyName ofClass:[model class]];
			if (elementValue != (id)kCFNull && nil != elementValue) {
				if ([class isEqual:[NSDate class]]) {
					NSDate* date = [self parseDateFromString:(propertyValue)];
					propertyValue = [self dateInLocalTime:date];
				}
			}
            
            // If we know the destination class, the property is not of the correct class, and the property value is not null or nil...
            // if (class && propertyValue && ![propertyValue isKindOfClass:class] && ![propertyValue isEqual:[NSNull null]]) {
            if (class && propertyValue && ![propertyValue isKindOfClass:class] && ![propertyValue isEqual:[NSNull null]]) {
                // Then we must cooerce the element (probably a string) into the correct class.
                // Currently this only supports NSNumbers (NSDates are handled above).
                // New cooersions will be added on an as-needed basis.
                if (class == [NSNumber class]) {
                    if ([propertyValue isEqualToString:@"true"] ||
                        [propertyValue isEqualToString:@"false"]) {
                        propertyValue = [NSNumber numberWithBool:[propertyValue isEqualToString:@"true"]];
                    } else {
                        propertyValue = [NSNumber numberWithDouble:[propertyValue doubleValue]];
                    }
                } else {
                    [NSException raise:@"NoElementValueConversionMethod" format:@"Don't know how to convert %@ (%@) to %@", propertyValue, [propertyValue class], class];
                }
            }
			
			[self updateModel:model ifNewPropertyValue:propertyValue forPropertyNamed:propertyName];
		}
	}
}

- (void)setRelationshipsOfModel:(NSObject<RKObjectMappable>*)object fromElements:(NSDictionary*)elements {
	NSDictionary* elementToRelationshipMappings = [[object class] elementToRelationshipMappings];
	for (NSString* elementKeyPath in elementToRelationshipMappings) {
		NSString* propertyName = [elementToRelationshipMappings objectForKey:elementKeyPath];
		
		id relationshipElements = nil;
		@try {
			relationshipElements = [elements valueForKeyPath:elementKeyPath];
		}
		@catch (NSException* e) {
			NSLog(@"Caught exception:%@ when trying valueForKeyPath with path:%@ for elements:%@", e, elementKeyPath, elements);
		}
        
        // NOTE: The last part of the keyPath contains the elementName for the mapped destination class of our children
        NSArray* componentsOfKeyPath = [elementKeyPath componentsSeparatedByString:@"."];
        NSString *className = [componentsOfKeyPath objectAtIndex:[componentsOfKeyPath count] - 1];
        Class modelClass = [_elementToClassMappings objectForKey:className];
        if ([modelClass isKindOfClass: [NSNull class]]) {
            NSLog(@"Warning: could not find a class mapping for relationship '%@':", className);
            NSLog(@"   parent class   : %@", [object class]);
            NSLog(@"   elements to map: %@", elements);
            NSLog(@"maybe you want to register your model with the object mapper or you want to pluralize the keypath?");
            break;
        }
        
        Class collectionClass = [self typeClassForProperty:propertyName ofClass:[object class]];
        if ([collectionClass isSubclassOfClass:[NSSet class]] || [collectionClass isSubclassOfClass:[NSArray class]])
        {
            id children = nil;
            if ([collectionClass isSubclassOfClass:[NSSet class]]) {
                children = [NSMutableSet setWithCapacity:[relationshipElements count]];
            } else if ([collectionClass isSubclassOfClass:[NSArray class]]) {
                children = [NSMutableArray arrayWithCapacity:[relationshipElements count]];
            }
            
            for (NSDictionary* childElements in relationshipElements) {				
                id child = [self createOrUpdateInstanceOfModelClass:modelClass fromElements:childElements];		
                if (child) {
                    [(NSMutableArray*)children addObject:child];
                }
            }
            
            [object setValue:children forKey:propertyName];
        } else if ([relationshipElements isKindOfClass:[NSDictionary class]]) {
            id child = [self createOrUpdateInstanceOfModelClass:modelClass fromElements:relationshipElements];		
            [object setValue:child forKey:propertyName];
        }
        
    }
    
    Class managedObjectClass = NSClassFromString(@"RKManagedObject");
    if (managedObjectClass && [object isKindOfClass:managedObjectClass]) {
        RKManagedObject* managedObject = (RKManagedObject*)object;
        NSDictionary* relationshipToPkPropertyMappings = [[managedObject class] relationshipToPrimaryKeyPropertyMappings];
        for (NSString* relationship in relationshipToPkPropertyMappings) {
            NSString* primaryKeyPropertyString = [relationshipToPkPropertyMappings objectForKey:relationship];
            
            NSNumber* objectPrimaryKeyValue = nil;
            @try {
                objectPrimaryKeyValue = [managedObject valueForKeyPath:primaryKeyPropertyString];
            } @catch (NSException* e) {
                NSLog(@"Caught exception:%@ when trying valueForKeyPath with path:%@ for object:%@", e, primaryKeyPropertyString, managedObject);
            }
            
            NSDictionary* relationshipsByName = [[managedObject entity] relationshipsByName];
            NSEntityDescription* relationshipDestinationEntity = [[relationshipsByName objectForKey:relationship] destinationEntity];
            id relationshipDestinationClass = objc_getClass([[relationshipDestinationEntity managedObjectClassName] cStringUsingEncoding:NSUTF8StringEncoding]);
            RKManagedObject* relationshipValue = [[[RKObjectManager sharedManager] objectStore] findOrCreateInstanceOfManagedObject:relationshipDestinationClass
                                                                                                                withPrimaryKeyValue:objectPrimaryKeyValue];
            if (relationshipValue) {
                [managedObject setValue:relationshipValue forKey:relationship];
            }
        }
    }

}

- (void)updateModel:(NSObject<RKObjectMappable>*)model fromElements:(NSDictionary*)elements {
	[self setPropertiesOfModel:model fromElements:elements];
	[self setRelationshipsOfModel:model fromElements:elements];
}

///////////////////////////////////////////////////////////////////////////////
// Date & Time Helpers

- (NSDate*)parseDateFromString:(NSString*)string {
	NSDate* date = nil;
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	// TODO: I changed this to local time and it fixes my date issues. wtf?
	[formatter setTimeZone:self.localTimeZone];
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

- (NSDate*)dateInLocalTime:(NSDate*)date {
	NSDate* destinationDate = nil;
	if (date) {
		NSInteger remoteGMTOffset = [self.remoteTimeZone secondsFromGMTForDate:date];
		NSInteger localGMTOffset = [self.localTimeZone secondsFromGMTForDate:date];
		NSTimeInterval interval = localGMTOffset - remoteGMTOffset;		
		destinationDate = [[[NSDate alloc] initWithTimeInterval:interval sinceDate:date] autorelease];
	}	
	return destinationDate;
}

@end
