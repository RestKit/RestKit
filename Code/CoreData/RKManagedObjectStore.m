//
//  RKManagedObjectStore.m
//  RestKit
//
//  Created by Blake Watters on 9/22/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKManagedObjectStore.h"
#import "RKAlert.h"

NSString* const RKManagedObjectStoreDidFailSaveNotification = @"RKManagedObjectStoreDidFailSaveNotification";
static NSString* const kRKManagedObjectContextKey = @"RKManagedObjectContext";

@interface RKManagedObjectStore (Private)
- (id)initWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)nilOrDirectoryPath usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel*)nilOrManagedObjectModel;
- (void)createPersistentStoreCoordinator;
- (void)createStoreIfNecessaryUsingSeedDatabase:(NSString*)seedDatabase;
- (NSString *)applicationDocumentsDirectory;
- (NSManagedObjectContext*)newManagedObjectContext;
@end

@implementation RKManagedObjectStore

@synthesize delegate = _delegate;
@synthesize storeFilename = _storeFilename;
@synthesize pathToStoreFile = _pathToStoreFile;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectCache = _managedObjectCache;

+ (RKManagedObjectStore*)objectStoreWithStoreFilename:(NSString*)storeFilename {
    return [self objectStoreWithStoreFilename:storeFilename usingSeedDatabaseName:nil managedObjectModel:nil];
}

+ (RKManagedObjectStore*)objectStoreWithStoreFilename:(NSString *)storeFilename usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel*)nilOrManagedObjectModel {
    return [[[self alloc] initWithStoreFilename:storeFilename inDirectory:nil usingSeedDatabaseName:nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:nilOrManagedObjectModel] autorelease];
}

+ (RKManagedObjectStore*)objectStoreWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)directory usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel*)nilOrManagedObjectModel {
    return [[[self alloc] initWithStoreFilename:storeFilename inDirectory:directory usingSeedDatabaseName:nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:nilOrManagedObjectModel] autorelease];
}

- (id)initWithStoreFilename:(NSString*)storeFilename {
	return [self initWithStoreFilename:storeFilename inDirectory:nil usingSeedDatabaseName:nil managedObjectModel:nil];
}

- (id)initWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)nilOrDirectoryPath usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel*)nilOrManagedObjectModel {
    self = [self init];
	if (self) {
		_storeFilename = [storeFilename retain];
		
		if( nilOrDirectoryPath == nil ) {
			nilOrDirectoryPath = [self applicationDocumentsDirectory];
		}
		else {
			BOOL isDir;
			NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:nilOrDirectoryPath isDirectory:&isDir] && isDir == YES, @"Specified storage directory exists", nilOrDirectoryPath);
		}
		_pathToStoreFile = [[nilOrDirectoryPath stringByAppendingPathComponent:_storeFilename] retain];
		
        if (nilOrManagedObjectModel == nil) {
            nilOrManagedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
        }
		_managedObjectModel = [nilOrManagedObjectModel retain];
		
        if (nilOrNameOfSeedDatabaseInMainBundle) {
            [self createStoreIfNecessaryUsingSeedDatabase:nilOrNameOfSeedDatabaseInMainBundle];
        }
		
		[self createPersistentStoreCoordinator];
	}
    
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	[_storeFilename release];
	_storeFilename = nil;
	[_pathToStoreFile release];
	_pathToStoreFile = nil;
    [_managedObjectModel release];
	_managedObjectModel = nil;
    [_persistentStoreCoordinator release];
	_persistentStoreCoordinator = nil;
	[_managedObjectCache release];
	_managedObjectCache = nil;
    
	[super dealloc];
}

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.
 */
- (NSError*)save {
	NSManagedObjectContext* moc = [self managedObjectContext];
    NSError *error;
	
	@try {
		if (![moc save:&error]) {
			if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToSaveContext:error:exception:)]) {
				[self.delegate managedObjectStore:self didFailToSaveContext:moc error:error exception:nil];
			}
			
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"];
			[[NSNotificationCenter defaultCenter] postNotificationName:RKManagedObjectStoreDidFailSaveNotification object:self userInfo:userInfo];
			
			return error;
		}
	}
	@catch (NSException* e) {
		if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToSaveContext:error:exception:)]) {
			[self.delegate managedObjectStore:self didFailToSaveContext:moc error:nil exception:e];
		}
		else {
			@throw;
		}
	}
	return nil;
}

- (NSManagedObjectContext*)newManagedObjectContext {
	NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] init];
	[managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
	[managedObjectContext setUndoManager:nil];
	[managedObjectContext setMergePolicy:NSOverwriteMergePolicy];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(objectsDidChange:)
												 name:NSManagedObjectContextObjectsDidChangeNotification
											   object:managedObjectContext];
	return managedObjectContext;
}

- (void)createStoreIfNecessaryUsingSeedDatabase:(NSString*)seedDatabase {
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:self.pathToStoreFile]) {
        NSString* seedDatabasePath = [[NSBundle mainBundle] pathForResource:seedDatabase ofType:nil];
        NSAssert1(seedDatabasePath, @"Unable to find seed database file '%@' in the Main Bundle, aborting...", seedDatabase);
        NSLog(@"No existing database found, copying from seed path '%@'", seedDatabasePath);
		
		NSError* error;
        if (![[NSFileManager defaultManager] copyItemAtPath:seedDatabasePath toPath:self.pathToStoreFile error:&error]) {
			if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToCopySeedDatabase:error:)]) {
				[self.delegate managedObjectStore:self didFailToCopySeedDatabase:seedDatabase error:error];
			} else {
				NSLog(@"Encountered an error during seed database copy: %@", [error localizedDescription]);
			}
        }
        NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:seedDatabasePath], @"Seed database not found at path '%@'!", seedDatabasePath);
    }
}

- (void)createPersistentStoreCoordinator {
	NSURL *storeUrl = [NSURL fileURLWithPath:self.pathToStoreFile];
	
	NSError *error;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];
	
	// Allow inferred migration from the original version of the application.
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
	
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
		if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToCreatePersistentStoreCoordinatorWithError:)]) {
			[self.delegate managedObjectStore:self didFailToCreatePersistentStoreCoordinatorWithError:error];
		}
		else {
			NSAssert(NO, @"Managed object store failed to create persistent store coordinator: %@", error);
		}
    }
}

- (void)deletePersistantStoreUsingSeedDatabaseName:(NSString *)seedFile {
	NSURL* storeUrl = [NSURL fileURLWithPath:self.pathToStoreFile];
	
	NSError* error;
	if (![[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:&error]) {
		if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToDeletePersistentStore:error:)]) {
			[self.delegate managedObjectStore:self didFailToDeletePersistentStore:self.pathToStoreFile error:error];
		}
		else {
			NSAssert(NO, @"Managed object store failed to delete persistent store : %@", error);
		}
	}
	
	[_persistentStoreCoordinator release];
	_persistentStoreCoordinator = nil;
	
	// Clear the current managed object context. Will be re-created next time it is accessed.
	NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
    if ([threadDictionary objectForKey:kRKManagedObjectContextKey]) {
        [threadDictionary removeObjectForKey:kRKManagedObjectContextKey];
    }
	
	if (seedFile)
		[self createStoreIfNecessaryUsingSeedDatabase:seedFile];

	[self createPersistentStoreCoordinator];
}

- (void)deletePersistantStore {
	[self deletePersistantStoreUsingSeedDatabaseName:nil];
}

/**
 *
 *	Override managedObjectContext getter to ensure we return a separate context
 *	for each NSThread.
 *
 */
-(NSManagedObjectContext*)managedObjectContext {
	NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
	NSManagedObjectContext* backgroundThreadContext = [threadDictionary objectForKey:kRKManagedObjectContextKey];
	if (!backgroundThreadContext) {
		backgroundThreadContext = [self newManagedObjectContext];					
		[threadDictionary setObject:backgroundThreadContext forKey:kRKManagedObjectContextKey];			
		[backgroundThreadContext release];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChanges:)
													 name:NSManagedObjectContextDidSaveNotification
												   object:backgroundThreadContext];
	}
	return backgroundThreadContext;
}

- (void)mergeChangesOnMainThreadWithNotification:(NSNotification*)notification {
	assert([NSThread isMainThread]);
	[self.managedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
											withObject:notification
										 waitUntilDone:YES];
}

- (void)mergeChanges:(NSNotification *)notification {
	// Merge changes into the main context on the main thread
	[self performSelectorOnMainThread:@selector(mergeChangesOnMainThreadWithNotification:) withObject:notification waitUntilDone:YES];
}

- (void)objectsDidChange:(NSNotification*)notification {
	NSDictionary* userInfo = notification.userInfo;
	NSSet* insertedObjects = [userInfo objectForKey:NSInsertedObjectsKey];
	NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
	
	for (NSManagedObject* object in insertedObjects) {
		if ([object respondsToSelector:@selector(primaryKeyProperty)]) {
			Class class = [object class];
			NSString* primaryKey = [class performSelector:@selector(primaryKeyProperty)];
			id primaryKeyValue = [object valueForKey:primaryKey];
			
			NSMutableDictionary* classCache = [threadDictionary objectForKey:class];
			if (classCache && primaryKeyValue && [classCache objectForKey:primaryKeyValue] == nil) {
				[classCache setObject:object forKey:primaryKeyValue];
			}
		}
	}
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

- (NSManagedObject*)objectWithID:(NSManagedObjectID*)objectID {
	return [self.managedObjectContext objectWithID:objectID];
}

- (NSArray*)objectsWithIDs:(NSArray*)objectIDs {
	NSMutableArray* objects = [[NSMutableArray alloc] init];
	for (NSManagedObjectID* objectID in objectIDs) {
		[objects addObject:[self.managedObjectContext objectWithID:objectID]];
	}
	NSArray* objectArray = [NSArray arrayWithArray:objects];
	[objects release];
	
	return objectArray;
}

- (RKManagedObject*)findOrCreateInstanceOfManagedObject:(Class)class withPrimaryKeyValue:(id)primaryKeyValue {
	RKManagedObject* object = nil;
	if ([class respondsToSelector:@selector(allObjects)]) {
		NSArray* objects = nil;
		NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
		
		if (nil == [threadDictionary objectForKey:class]) {
			NSFetchRequest* fetchRequest = [class fetchRequest];
			[fetchRequest setReturnsObjectsAsFaults:NO];			
			objects = [class objectsWithFetchRequest:fetchRequest];
			NSLog(@"Caching all %d %@ objects to thread local storage", [objects count], class);
			NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
			NSString* primaryKey = [class performSelector:@selector(primaryKeyProperty)];
			for (id theObject in objects) {			
				id primaryKeyValue = [theObject valueForKey:primaryKey];
				if (primaryKeyValue) {
					[dictionary setObject:theObject forKey:primaryKeyValue];
				}
			}
			
			[threadDictionary setObject:dictionary forKey:class];
		}
		
		NSMutableDictionary* dictionary = [threadDictionary objectForKey:class];
		object = [dictionary objectForKey:primaryKeyValue];
		
		if (object == nil && primaryKeyValue && [class respondsToSelector:@selector(object)]) {
			object = [class object];
			[dictionary setObject:object forKey:primaryKeyValue];
		}
	}
	return object;
}

- (NSArray*)objectsForResourcePath:(NSString *)resourcePath {
    NSArray* cachedObjects = nil;
    
    if (self.managedObjectCache) {
        NSArray* cacheFetchRequests = [self.managedObjectCache fetchRequestsForResourcePath:resourcePath];
        cachedObjects = [RKManagedObject objectsWithFetchRequests:cacheFetchRequests];
    }
    
    return cachedObjects;
}

@end
