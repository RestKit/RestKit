//
//  OTRestManagedObjectStore.m
//  OTRestFramework
//
//  Created by Blake Watters on 9/22/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "OTRestManagedObjectStore.h"

@interface OTRestManagedObjectStore (Private)
- (void)createPersistentStoreCoordinator;
- (NSString *)applicationDocumentsDirectory;
@end

@implementation OTRestManagedObjectStore

@synthesize storeFilename = _storeFilename;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectContext = _managedObjectContext;

- (id)initWithStoreFilename:(NSString*)storeFilename {
	if (self = [self init]) {
		_storeFilename = [storeFilename retain];
		_managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
		[self createPersistentStoreCoordinator];
		_managedObjectContext = [[NSManagedObjectContext alloc] init];
		_managedObjectContext.persistentStoreCoordinator = _persistentStoreCoordinator;
	}
	
	return self;
}

- (void)dealloc {
	[_storeFilename release];
	[_managedObjectContext release];
    [_managedObjectModel release];
    [_persistentStoreCoordinator release];
	[super dealloc];
}

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.
 */
- (NSError*)save {
    NSError *error;
    if (NO == [[self managedObjectContext] save:&error]) {
		return error;
    } else {
		return nil;
	}
}

- (void)createPersistentStoreCoordinator {
	NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:_storeFilename]];
	
	NSError *error;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
	
	// Allow inferred migration from the original version of the application.
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
        // Handle the error.
    }
}

- (void)deletePersistantStore {
	NSURL* storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:_storeFilename]];
	NSError* error = nil;
	NSLog(@"Error removing persistant store: %@", [error localizedDescription]);
	if (error) {
		//Handle error
	}
	error = nil;
	[[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:&error];
	if (error) {
		//Handle error
	}
	[_persistentStoreCoordinator release];
	[_managedObjectContext release];
	[self createPersistentStoreCoordinator];
	_managedObjectContext = [[NSManagedObjectContext alloc] init];
	_managedObjectContext.persistentStoreCoordinator = _persistentStoreCoordinator;
}

#pragma mark -
#pragma mark Helpers

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

@end
