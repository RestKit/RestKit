//
//  RKManagedObjectStore.m
//  RestKit
//
//  Created by Blake Watters on 9/22/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKManagedObjectStore.h"
#import <UIKit/UIKit.h>

NSString* const RKManagedObjectStoreDidFailSaveNotification = @"RKManagedObjectStoreDidFailSaveNotification";
static NSString* const kRKManagedObjectContextKey = @"RKManagedObjectContext";

@interface RKManagedObjectStore (Private)
- (void)createPersistentStoreCoordinator;
- (NSString *)applicationDocumentsDirectory;
- (NSManagedObjectContext*)createManagedObjectContext;
@end

@implementation RKManagedObjectStore

@synthesize storeFilename = _storeFilename;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectContext = _managedObjectContext;

- (id)initWithStoreFilename:(NSString*)storeFilename {
	if (self = [self init]) {
		_storeFilename = [storeFilename retain];
		_managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
		[self createPersistentStoreCoordinator];
		_managedObjectContext = [self createManagedObjectContext];
	}
	
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
    NSError *error = nil;
	@try {
		[[self managedObjectContext] save:&error];
	}
	@catch (NSException* e) {
		// TODO: This needs to be reworked into a delegation pattern
		NSString* errorMessage = [NSString stringWithFormat:@"An unrecoverable error was encountered while trying to save the database: %@", [e reason]];
		UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Ruh roh.", nil) 
														message:errorMessage
													   delegate:nil 
											  cancelButtonTitle:NSLocalizedString(@"OK", nil) 
											  otherButtonTitles:nil];
		[alert show];
		[alert release];
	} 
	@finally {
		if (error) {
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"];
			[[NSNotificationCenter defaultCenter] postNotificationName:RKManagedObjectStoreDidFailSaveNotification object:self userInfo:userInfo];
		}
		return error;
	}
}

- (NSManagedObjectContext*)createManagedObjectContext {
	NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] init];
	[managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	[managedObjectContext setUndoManager:nil];
	[managedObjectContext setMergePolicy:NSOverwriteMergePolicy];
	
	return managedObjectContext;
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
		// TODO: Needs to be handled with delegation... Allow the application to handle migration.
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
	_managedObjectContext = [self createManagedObjectContext];
}

/**
 *
 *	Override managedObjectContext getter to ensure we return a separate context
 *	for each NSThread.
 *
 */
-(NSManagedObjectContext*)managedObjectContext {
	if ([NSThread isMainThread]) {
		return _managedObjectContext;
	} else {
		NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
		NSManagedObjectContext* backgroundThreadContext = [threadDictionary objectForKey:kRKManagedObjectContextKey];
		if (!backgroundThreadContext) {
			backgroundThreadContext = [self createManagedObjectContext];					
			[threadDictionary setObject:backgroundThreadContext forKey:kRKManagedObjectContextKey];			
			[backgroundThreadContext release];
			
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChanges:)
														 name:NSManagedObjectContextDidSaveNotification
													   object:backgroundThreadContext];
		}
		return backgroundThreadContext;
	}
}

- (void)mergeChanges:(NSNotification *)notification {	
	// Merge changes into the main context on the main thread
	[_managedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
											withObject:notification
										 waitUntilDone:YES];
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
