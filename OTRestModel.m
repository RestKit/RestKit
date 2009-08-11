//
//  OTRestModel.m
//  TimeTrackerOSX
//
//  Created by Jeremy Ellison on 8/8/09.
//  Copyright 2009 Objective3. All rights reserved.
//

#import "OTRestModel.h"
#import "OTRestClient.h"

#import <objc/runtime.h>

@implementation OTRestModel

+ (NSString*)restId {
	// TODO: there has to be a better way to do this
	for (NSString* key in [[[self class] propertyMappings] allKeys]) {
		NSString* obj = (NSString*)[[[self class] propertyMappings] objectForKey:key];
		if ([obj isEqualToString:@"id"]) {
			return key;
		}
	}
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

+ (NSString*)entityName {
	const char* name = class_getName([self class]);
	NSString* className = [NSString stringWithCString:name];
	return className;
}

+ (NSDictionary*)propertyMappings {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

+ (NSDictionary*)relationshipMappings {
	//Not required, you might not have any relationships
	return nil;
}

+ (NSEntityDescription*)entity {
	return [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:context];
}

+ (NSFetchRequest*)request {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [self entity];
	[request setEntity:entity];
	[request autorelease];
	return request;
}

+ (NSArray*)collectionWithRequest:(NSFetchRequest*)request {
	NSError* error = nil;
	//NSLog(@"Context: %@", context);
	NSArray* collection = [context executeFetchRequest:request error:&error];
	if (error != nil) {
		NSLog(@"Error: %@", [error localizedDescription]);
	}
	return collection;
}

+ (id)objectWithRequest:(NSFetchRequest*)request {
	[request setFetchLimit:1];
	NSArray* collection = [self collectionWithRequest:request];
	if ([collection count] == 0)
		return nil;
	return [collection objectAtIndex:0];
}

+ (id)objectWithRestId:(NSNumber*)restId {
	NSFetchRequest* request = [self request];
	
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K = %@", [self restId], restId];
	[request setPredicate:predicate];
	
	return [self objectWithRequest:request];
}

+ (NSArray*)allObjects {
	return [self collectionWithRequest:[self request]];
}

+ (NSArray*)allObjectsOrderedBy:(NSString*)key {
	NSFetchRequest* request = [self request];
	
	NSSortDescriptor* sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:key 
																	ascending:YES
																	 selector:@selector(caseInsensitiveCompare:)] 
										autorelease];
	NSArray* sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	[request setSortDescriptors:sortDescriptors];
	
	return [self collectionWithRequest:request];
}

+ (id)createOrUpdateAttributesFromXML:(Element*)XML {
	NSNumber* objectId = [XML contentsNumberOfChildElement:@"id"];
	id object = [self objectWithRestId:objectId];
	if (object == nil) {
		// Create new
		object = [self createNewObjectFromElement:XML];
	} else {
		// Update
		[object updateObjectWithElement:XML];
	}
	
	return object;
}

+ (id)createNewObject {
	return [[[self class] alloc] initWithEntity:[[self class] entity] insertIntoManagedObjectContext:context];
}

+ (id)createNewObjectFromElement:(Element*)element {
	id object = [self createNewObject];
	return [object updateObjectWithElement:element];
}

- (void)updateAttributeForKey:(NSString*)key withElement:(Element*)element {
	NSAttributeDescription* attributeDescription = [[[self entity] attributesByName] objectForKey:key];
	NSString* elementName = [[[self class] propertyMappings] objectForKey:key];
	id originalValue = [self valueForKey:key];
	
	if ([[attributeDescription attributeValueClassName] isEqualToString:@"NSNumber"]) {
		NSNumber* value = [element contentsNumberOfChildElement:elementName];
		if (originalValue == nil || ![value isEqualToNumber:originalValue]) {
			[self setValue:value forKey:key];
		}
	} else if ([[attributeDescription attributeValueClassName] isEqualToString:@"NSString"]) {
		NSString* value = [element contentsTextOfChildElement:elementName];
		if (originalValue == nil || ![value isEqualToString:originalValue]) {
			[self setValue:value forKey:key];
		}
	} else if ([[attributeDescription attributeValueClassName] isEqualToString:@"NSDate"]) {
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:kRailsToXMLDateFormatterString];
		NSDate* value = [formatter dateFromString:[element contentsTextOfChildElement:elementName]];
		if (originalValue == nil || ![value isEqualToDate:originalValue]) {
			[self setValue:value forKey:key];
		}
		[formatter release];
	} else {
		[NSException raise:@"Property Type Not Handled" format:@"The Attribute Type %d has not yet been handled.", [attributeDescription attributeType]];
	}
}

- (void)updateAssociationForKey:(NSString*)key withElement:(Element*)element {
	NSRelationshipDescription* relationshipDescription = [[[self entity] relationshipsByName] objectForKey:key];
	if ([relationshipDescription isToMany]) {
		NSArray* associationElements = [element selectElements:[[[self class] relationshipMappings] objectForKey:key]];
		NSMutableSet* associationObjects = [NSMutableSet set];
		for (Element* associationElement in associationElements) {
			id associationObject = [[[OTRestClient client] mapper] buildModelFromXML:associationElement];
			[associationObjects addObject:associationObject];
		}
		[self setValue:associationObjects forKey:key];
	} else {
		// Not actually tested up to this point...
		Element* associationElement = [element selectElement:[[[self class] relationshipMappings] objectForKey:key]];
		id associatedObject = [[[OTRestClient client] mapper] buildModelFromXML:associationElement];
		[self setValue:associatedObject forKey:key];
	}
}

- (id)updateObjectWithElement:(Element*)element {
	//NSLog(@"Element: %@", element);
	
	for (NSString* key in [[[self class] propertyMappings] allKeys]) {
		[self updateAttributeForKey:key withElement:element];
	}
	
	for (NSString* key in [[[self class] relationshipMappings] allKeys]) {
		[self updateAssociationForKey:key withElement:element];
		
	}
	
	return self;
}



@end
