//
//  RKManagedObject.m
//  RestKit
//
//  Created by Blake Watters on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKManagedObject.h"
#import "NSString+InflectionSupport.h"
#import <objc/runtime.h>

@implementation RKManagedObject

#pragma mark -
#pragma mark NSManagedObject helper methods

// TODO: The managedObjectContext should be settable at the class level to ease coupling with
// singleton object manager
+ (NSManagedObjectContext*)managedObjectContext {
	return [[[RKObjectManager globalManager] objectStore] managedObjectContext];
}

// TODO: Move to new home!
+ (NSManagedObject*)objectWithID:(NSManagedObjectID*)objectID {
	return [[RKManagedObject managedObjectContext] objectWithID:objectID];
}

// TODO: Move to new home!
+ (NSArray*)objectsWithIDs:(NSArray*)objectIDs {
	NSMutableArray* objects = [[NSMutableArray alloc] init];
	for (NSManagedObjectID* objectID in objectIDs) {
		[objects addObject:[[RKManagedObject managedObjectContext] objectWithID:objectID]];
	}
	NSArray* objectArray = [NSArray arrayWithArray:objects];
	[objects release];
	
	return objectArray;
}

+ (NSEntityDescription*)entity {
	NSString* className = [NSString stringWithCString:class_getName([self class]) encoding:NSASCIIStringEncoding];
	return [NSEntityDescription entityForName:className inManagedObjectContext:[RKManagedObject managedObjectContext]];
}

+ (NSFetchRequest*)fetchRequest {
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [self entity];
	[fetchRequest setEntity:entity];
	return fetchRequest;
}

+ (NSArray*)objectsWithFetchRequest:(NSFetchRequest*)fetchRequest {
	NSError* error = nil;
	NSArray* objects = [[RKManagedObject managedObjectContext] executeFetchRequest:fetchRequest error:&error];
	if (error != nil) {
		NSLog(@"Error: %@", [error localizedDescription]);
		// TODO: Error handling
	}
	return objects;
}

+ (NSArray*)objectsWithFetchRequests:(NSArray*)fetchRequests {
	NSMutableArray* mutableObjectArray = [[NSMutableArray alloc] init];
	for (NSFetchRequest* fetchRequest in fetchRequests) {
		[mutableObjectArray addObjectsFromArray:[RKManagedObject objectsWithFetchRequest:fetchRequest]];
	}
	NSArray* objects = [NSArray arrayWithArray:mutableObjectArray];
	[mutableObjectArray release];
	return objects;
}

+ (id)objectWithFetchRequest:(NSFetchRequest*)fetchRequest {
	[fetchRequest setFetchLimit:1];
	NSArray* objects = [self objectsWithFetchRequest:fetchRequest];
	if ([objects count] == 0) {
		return nil;
	} else {
		return [objects objectAtIndex:0];
	}	
}

+ (NSArray*)objectsWithPredicate:(NSPredicate*)predicate {
	NSFetchRequest* fetchRequest = [self fetchRequest];
	[fetchRequest setPredicate:predicate];
	return [self objectsWithFetchRequest:fetchRequest];
}

+ (id)objectWithPredicate:(NSPredicate*)predicate {
	NSFetchRequest* fetchRequest = [self fetchRequest];
	[fetchRequest setPredicate:predicate];
	return [self objectWithFetchRequest:fetchRequest];
}

+ (NSArray*)allObjects {
	return [self objectsWithPredicate:nil];
}

+ (NSUInteger)count {
	NSFetchRequest *fetchRequest = [self fetchRequest];	
	NSError *error = nil;
	NSUInteger count = [[RKManagedObject managedObjectContext] countForFetchRequest:fetchRequest error:&error];
	// TODO: Error handling...
	return count;
}

+ (id)object {
	id object = [[self alloc] initWithEntity:[self entity] insertIntoManagedObjectContext:[RKManagedObject managedObjectContext]];
	return [object autorelease];
}

#pragma mark -
#pragma mark RKObjectMappable

// TODO: Would be nice to specify this via an annotation in the mappings definition...
+ (NSString*)primaryKey {
	return @"railsID";
}

// TODO: Would be nice to specify this via an annotation in the mappings definition...
+ (NSString*)primaryKeyElement {
	return @"id";
}

/**
 * TODO: Unwind assumptions about the primaryKey
 *
 * Right now we make the blanket assumption that Primary Keys are stored as NSNumber values. We
 * cast from NSStrings into NSNumbers to fix a weird bug Jeremy encountered with the subtle predicate
 * differences causes nil return values in some cases. This needs to be better understood and the assumptions
 * unwound.
 */
+ (id)findByPrimaryKey:(id)value {
	id primaryKeyValue = nil;
	if ([value isKindOfClass:[NSString class]]) {
		// Cast from string to a number
		primaryKeyValue = [NSNumber numberWithInt:[(NSString*)value integerValue]];
	} else {
		// Make blind assumption here.
		primaryKeyValue = value;
	}
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K = %@", [self primaryKey], primaryKeyValue];
 	return [self objectWithPredicate:predicate];
}

+ (NSDictionary*)elementToPropertyMappings {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

+ (NSDictionary*)elementToRelationshipMappings {
	return [NSDictionary dictionary];
}

+ (NSArray*)elementNames {
	return [[self elementToPropertyMappings] allKeys];
}

+ (NSArray*)propertyNames {
	return [[self elementToPropertyMappings] allValues];
}

// TODO: I get eliminated...
+ (NSString*)formatElementName:(NSString*)elementName forMappingFormat:(RKMappingFormat)format {
	if (RKMappingFormatXML == format) {
		return [[elementName camelize] dasherize];
	} else if (RKMappingFormatJSON == format) {
		return [[elementName camelize] underscore];
	}
	
	return elementName;
}

// TODO: I get eliminated...
+ (NSString*)modelName {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

#pragma mark Helpers

- (NSDictionary*)elementNamesAndPropertyValues {
	NSDictionary* mappings = [[self class] elementToPropertyMappings];
	NSMutableDictionary* elementsAndPropertyValues = [NSMutableDictionary dictionaryWithCapacity:[mappings count]];
	// Return all the properties of this model in a dictionary under their element names
	for (NSString* elementName in mappings) {
		NSString* propertyName = [mappings valueForKey:elementName];
		id propertyValue = [self valueForKey:propertyName];
		[elementsAndPropertyValues setValue:propertyValue forKey:elementName];
	}
	
	return (NSDictionary*) elementsAndPropertyValues;
}

// TODO: This implementation is Rails specific. Consider using an adapter approach.
// TODO: Gets handled in a Rails adapter, moved completely off the model itself...
// TODO: Moves to the model mapper? encodeProperties:?
- (NSDictionary*)paramsForSerialization {
	NSDictionary* elementsAndProperties = [self elementNamesAndPropertyValues];
	NSMutableDictionary* resourceParams = [NSMutableDictionary dictionaryWithCapacity:[elementsAndProperties count]];
	// TODO: Eliminate modelName somehow... should be using the name of the element this class was registered for!
	NSString* underscoredModelName = [[[self class] modelName] underscore];
	for (NSString* elementName in [elementsAndProperties allKeys]) {
		id value = [elementsAndProperties valueForKey:elementName];
		NSString* attributeName = [elementName stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
		if (![attributeName isEqualToString:@"id"]) {
			NSString* keyName = [NSString stringWithFormat:@"%@[%@]", underscoredModelName, attributeName];
			[resourceParams setValue:value forKey:keyName];
		}
	}
	
	return resourceParams;
}

- (BOOL)isNew {
    NSDictionary *vals = [self committedValuesForKeys:nil];
    return [vals count] == 0;
}

@end
