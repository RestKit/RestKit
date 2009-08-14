//
//  OTManagedModel.m
//  OTRestFramework
//
//  Created by Blake Watters on 8/14/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import "OTRestManagedModel.h"


@implementation OTRestManagedModel

#pragma mark -
#pragma mark NSManagedObject helper methods

+ (NSEntityDescription*)entity {
	return [NSEntityDescription entityForName:[[self class] className] inManagedObjectContext:context];
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
#pragma mark OTModelMapper informal protocol

+ (id)newObject {
	id model = [[self alloc] initWithEntity:[self entity] insertIntoManagedObjectContext:context];
	return [model autorelease];
}

+ (NSString*)primaryKey {
	return @"id";
}

+ (id)findByPrimaryKey:(id)value {
	NSString* pk = [[self elementToPropertyMappings] objectForKey:[self primaryKey]];
	NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K = %@", pk, value];
	return [self objectWithPredicate:predicate];
}

+ (NSDictionary*)elementToPropertyMappings {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

+ (NSDictionary*)elementToRelationshipMappings {
	return [NSDictionary dictionary];
}

@end
