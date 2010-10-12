//
//  RKObjectSeeder.m
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKObjectSeeder.h"
#import "RKManagedObjectStore.h"

@implementation RKObjectSeeder

- (id)initWithObjectManager:(RKObjectManager*)manager {
	if (self = [self init]) {
		_manager = [manager retain];
	}
	
	return self;
}

- (void)dealloc {
	[_manager release];
	[super dealloc];
}

- (NSArray*)seedDatabaseWithBundledFile:(NSString*)fileName ofType:(NSString*)type {
	NSError* error = nil;
	NSString* filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:type];
	NSString* payload = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
	if (nil == error) {
		return [[_manager mapper] mapFromString:payload];
	}
	
	return nil;
}

- (void)seedDatabaseWithBundledFiles:(NSArray*)fileNames ofType:(NSString*)type {
	NSLog(@"[RestKit] RKModelSeeder: Seeding database with contents of %d %@ files...", [fileNames count], [type uppercaseString]);
	for (NSString* fileName in fileNames) {
		NSArray* objects = [self seedDatabaseWithBundledFile:fileName ofType:type];
		NSLog(@"[RestKit] RKModelSeeder: Seeded %d objects from %@...", [objects count], [NSString stringWithFormat:@"%@.%@", fileName, type]);
	}
	
	[self finalizeSeedingAndExit];
}

- (void)seedObjectsFromFile:(NSString*)fileName ofType:(NSString*)type toClass:(Class)theClass keyPath:(NSString*)keyPath {
	NSError* error = nil;
	NSString* filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:type];
	NSString* payload = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
	if (nil == error) {
		id objects = [_manager.mapper parseString:payload];
		NSAssert1(objects != nil, @"Unable to parse data from file %@", filePath);		
		id parseableObjects = [objects valueForKeyPath:keyPath];
		NSAssert1([parseableObjects isKindOfClass:[NSArray class]], @"Expected an NSArray of objects, got %@", objects);
		NSAssert1([[parseableObjects objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"Expected an array of NSDictionaries, got %@", [objects objectAtIndex:0]);
		
		NSArray* mappedObjects = [_manager.mapper mapObjectsFromArrayOfDictionaries:parseableObjects toClass:theClass];
		NSLog(@"[RestKit] RKModelSeeder: Seeded %d objects from %@...", [mappedObjects count], [NSString stringWithFormat:@"%@.%@", fileName, type]);
	} else {
		NSLog(@"Unable to read file %@ with type %@: %@", fileName, type, [error localizedDescription]);
	}
}

- (void)finalizeSeedingAndExit {
	NSError* error = [[_manager objectStore] save];
	if (error != nil) {
		NSLog(@"[RestKit] RKModelSeeder: Error saving object context: %@", [error localizedDescription]);
	}
	
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	NSString* storeFileName = [[_manager objectStore] storeFilename];
	NSString* destinationPath = [basePath stringByAppendingPathComponent:storeFileName];
	NSLog(@"[RestKit] RKModelSeeder: A Pre-loaded database has been generated at %@. Please copy into Resources/", destinationPath);
	
	exit(1);
}

@end
