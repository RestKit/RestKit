//
//  OTManagedModel.m
//  OTRestFramework
//
//  Created by Blake Watters on 8/14/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import "OTRestManagedModel.h"
#import "NSString+InflectionSupport.h"
#import <objc/runtime.h>

@implementation OTRestManagedModel

#pragma mark -
#pragma mark NSManagedObject helper methods

+ (NSManagedObjectContext*)managedObjectContext {
	return [[[OTRestModelManager manager] objectStore] managedObjectContext];
}

+ (NSEntityDescription*)entity {
	NSString* className = [NSString stringWithCString:class_getName([self class]) encoding:NSASCIIStringEncoding];
	return [NSEntityDescription entityForName:className inManagedObjectContext:[self managedObjectContext]];
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
//	NSLog(@"About to perform a collection request: %@", request);
	NSArray* collection = [[self managedObjectContext] executeFetchRequest:request error:&error];
	if (error != nil) {
		NSLog(@"Error: %@", [error localizedDescription]);
		// TODO: Error handling
	}
	return collection;
}

+ (id)objectWithRequest:(NSFetchRequest*)request {
	[request setFetchLimit:1];
	NSArray* collection = [self collectionWithRequest:request];
	if ([collection count] == 0) {
		return nil;
	} else {
		return [collection objectAtIndex:0];
	}	
}

+ (NSArray*)collectionWithPredicate:(NSPredicate*)predicate {
	NSFetchRequest* request = [self request];
	[request setPredicate:predicate];
	return [self collectionWithRequest:request];
}

+ (id)objectWithPredicate:(NSPredicate*)predicate {
	NSFetchRequest* request = [self request];
	[request setPredicate:predicate];
	return [self objectWithRequest:request];
}

+ (NSArray*)allObjects {
	return [self collectionWithPredicate:nil];
}

#pragma mark -
#pragma mark OTRestModelMappable

// TODO: All this path shit needs cleaning up...
- (NSString*)resourcePath {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

// TODO: The .xml format should NOT be specified here!
- (NSString*)collectionPath {
	return [NSString stringWithFormat:@"%@.xml", [self resourcePath]];
}

- (NSString*)memberPath {
	NSLog(@"Was asked for memberPath. primaryKeyValue is %@. self = %@", [self valueForKey:[[self class] primaryKey]], self);
	return [NSString stringWithFormat:@"%@/%@.xml", [self resourcePath], [self valueForKey:[[self class] primaryKey]]];
}

+ (id)newObject {
	id model = [[self alloc] initWithEntity:[self entity] insertIntoManagedObjectContext:[self managedObjectContext]];
	return [model autorelease];
}

+ (NSString*)primaryKey {
	return @"ID";
}

+ (NSString*)primaryKeyElement {
	return @"id";
}

+ (id)findByPrimaryKey:(id)value {
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K = %@", [self primaryKey], value];
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
- (NSDictionary*)resourceParams {
	NSDictionary* elementsAndProperties = [self elementNamesAndPropertyValues];
	NSMutableDictionary* resourceParams = [NSMutableDictionary dictionaryWithCapacity:[elementsAndProperties count]];	
	NSString* underscoredModelName = [[[self class] modelName] underscore];
	for (NSString* elementName in [elementsAndProperties allKeys]) {
		id value = [elementsAndProperties valueForKey:elementName];
		NSString* attributeName = [elementName stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
		NSString* keyName = [NSString stringWithFormat:@"%@[%@]", underscoredModelName, attributeName];
		[resourceParams setValue:value forKey:keyName];
	}
	
	return resourceParams;
}

// TODO: Should this handle persistence to the web also? Should the model manager do it instead? How do we handle deletes? creation? need flags?
- (NSError*)save {
	NSError* error = nil;
	[[self managedObjectContext] save:&error];
	if (nil != error) {
		NSLog(@"Error saving persistent store: %@", error);
	}
	return error;
}

// TODO: Delete on the server also? See above.
- (void)destroy {	
	[[self managedObjectContext] deleteObject:self];
}

- (void)setAttributesFromXML:(Element*)XML {
	[[[OTRestModelManager manager] mapper] setAttributes:self fromXML:XML];
}

@end
