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

// TODO: The object store should be settable at the class level to ease coupling with
// shared object manager
+ (NSManagedObjectContext*)managedObjectContext {
	return [[[RKObjectManager sharedManager] objectStore] managedObjectContext];
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

+ (NSUInteger)count:(NSError**)error {
	NSFetchRequest* fetchRequest = [self fetchRequest];
	return [[RKManagedObject managedObjectContext] countForFetchRequest:fetchRequest error:error];
}

+ (NSUInteger)count {
	NSError *error = nil;
	return [self count:&error];
}

+ (id)object {
	id object = [[self alloc] initWithEntity:[self entity] insertIntoManagedObjectContext:[RKManagedObject managedObjectContext]];
	return [object autorelease];
}

#pragma mark -
#pragma mark RKObjectMappable

+ (NSString*)primaryKeyProperty {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

+ (NSString*)primaryKeyElement {
	NSDictionary* mappings = [[self class] elementToPropertyMappings];
	for (NSString* elementName in mappings) {
		NSString* propertyName = [mappings valueForKey:elementName];
		if ([propertyName isEqualToString:[self primaryKeyProperty]]) {
			return elementName;
		}
	}

	// Blow up if not found
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

/**
 * TODO: Unwind assumptions about the primaryKey
 *
 * Right now we make the blanket assumption that Primary Keys are stored as NSNumber values. We
 * cast from NSStrings into NSNumbers to fix a weird bug Jeremy encountered with the subtle predicate
 * differences causes nil return values in some cases. This needs to be better understood and the assumptions
 * unwound.
 */
// TODO: Need to inspect the property type here...
+ (id)objectWithPrimaryKeyValue:(id)value {
	id primaryKeyValue = nil;
	if ([value isKindOfClass:[NSString class]]) {
		// Cast from string to a number
		primaryKeyValue = [NSNumber numberWithInt:[(NSString*)value integerValue]];
	} else {
		// Make blind assumption here.
		primaryKeyValue = value;
	}
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K = %@", [self primaryKeyProperty], primaryKeyValue];
 	return [self objectWithPredicate:predicate];
}

+ (NSDictionary*)elementToPropertyMappings {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

+ (NSDictionary*)elementToRelationshipMappings {
	return [NSDictionary dictionary];
}

+ (NSDictionary*)relationshipToPrimaryKeyPropertyMappings {
	return [NSDictionary dictionary];
}

#pragma mark Helpers

- (id)primaryKeyValue {
	return [self valueForKey:[[self class] primaryKeyProperty]];
}

- (NSDictionary*)propertiesForSerialization {
	return RKObjectMappableGetPropertiesByElement(self);
}

- (BOOL)isNew {
    NSDictionary *vals = [self committedValuesForKeys:nil];
    return [vals count] == 0;
}

@end
