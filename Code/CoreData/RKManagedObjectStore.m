//
//  RKManagedObjectStore.m
//  RestKit
//
//  Created by Blake Watters on 9/22/09.
//  Copyright 2009 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKManagedObjectStore.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKLog.h"
#import "RKSearchWordObserver.h"
#import "RKObjectPropertyInspector.h"
#import "RKObjectPropertyInspector+CoreData.h"
#import "RKAlert.h"
#import "RKLog.h"
#import "RKDirectory.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

NSString* const RKManagedObjectStoreDidFailSaveNotification = @"RKManagedObjectStoreDidFailSaveNotification";
static NSString* const RKManagedObjectStoreThreadDictionaryContextKey = @"RKManagedObjectStoreThreadDictionaryContextKey";
static NSString* const RKManagedObjectStoreThreadDictionaryEntityCacheKey = @"RKManagedObjectStoreThreadDictionaryEntityCacheKey";

@interface RKManagedObjectStore (Private)
- (id)initWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)nilOrDirectoryPath usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel*)nilOrManagedObjectModel delegate:(id)delegate;
- (void)createPersistentStoreCoordinator;
- (void)createStoreIfNecessaryUsingSeedDatabase:(NSString*)seedDatabase;
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
    return [self objectStoreWithStoreFilename:storeFilename usingSeedDatabaseName:nil managedObjectModel:nil delegate:nil];
}

+ (RKManagedObjectStore*)objectStoreWithStoreFilename:(NSString *)storeFilename usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel*)nilOrManagedObjectModel delegate:(id)delegate {
    return [[[self alloc] initWithStoreFilename:storeFilename inDirectory:nil usingSeedDatabaseName:nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:nilOrManagedObjectModel delegate:delegate] autorelease];
}

+ (RKManagedObjectStore*)objectStoreWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)directory usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel*)nilOrManagedObjectModel delegate:(id)delegate {
    return [[[self alloc] initWithStoreFilename:storeFilename inDirectory:directory usingSeedDatabaseName:nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:nilOrManagedObjectModel delegate:delegate] autorelease];
}

- (id)initWithStoreFilename:(NSString*)storeFilename {
	return [self initWithStoreFilename:storeFilename inDirectory:nil usingSeedDatabaseName:nil managedObjectModel:nil delegate:nil];
}

- (id)initWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)nilOrDirectoryPath usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel*)nilOrManagedObjectModel delegate:(id)delegate {
    self = [self init];
	if (self) {
		_storeFilename = [storeFilename retain];

		if (nilOrDirectoryPath == nil) {
			nilOrDirectoryPath = [RKDirectory applicationDataDirectory];
		} else {
			BOOL isDir;
			NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:nilOrDirectoryPath isDirectory:&isDir] && isDir == YES, @"Specified storage directory exists", nilOrDirectoryPath);
		}
		_pathToStoreFile = [[nilOrDirectoryPath stringByAppendingPathComponent:_storeFilename] retain];

        if (nilOrManagedObjectModel == nil) {
            // NOTE: allBundles permits Core Data setup in unit tests
			nilOrManagedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
        }
		NSMutableArray* allManagedObjectModels = [[NSMutableArray alloc] init];
		[allManagedObjectModels addObject:nilOrManagedObjectModel];

		NSString* rkBundlePath = [[NSBundle mainBundle] pathForResource:@"RestKitResources"
																 ofType:@"bundle"];
		NSURL* rkCoreDataLibraryMOMURL = [[NSBundle bundleWithPath:rkBundlePath] URLForResource:@"RestKitCoreData"
																				  withExtension:@"momd"];
		NSManagedObjectModel* rkCoreDataLibraryMOM = [[NSManagedObjectModel alloc] initWithContentsOfURL:rkCoreDataLibraryMOMURL];
        if (rkCoreDataLibraryMOM) {
            [allManagedObjectModels addObject:rkCoreDataLibraryMOM];
            [rkCoreDataLibraryMOM release];
        } else {
            RKLogWarning(@"Unable to find RestKitCoreData.momd within the RestKitCoreDataBundle.bundle");
        }

		_managedObjectModel = [[NSManagedObjectModel modelByMergingModels:allManagedObjectModels] retain];
		[allManagedObjectModels release];

        if (nilOrNameOfSeedDatabaseInMainBundle) {
            [self createStoreIfNecessaryUsingSeedDatabase:nilOrNameOfSeedDatabaseInMainBundle];
        }
        
        //Add queue to core data model before persistant store is created
        //TODO: Check if exists before creating new entity. This doesn't seem necessary (Core Data handles internally?)
        NSEntityDescription *syncQueue = [[NSEntityDescription alloc] init];
        [syncQueue setName: @"RKManagedObjectSyncQueue"];
        [syncQueue setManagedObjectClassName: @"RKManagedObjectSyncQueue"];
        [syncQueue setAbstract:NO];
        
        NSAttributeDescription *queuePositionAttribute = [[NSAttributeDescription alloc] init];
        [queuePositionAttribute setName:@"queuePosition"];
        [queuePositionAttribute setAttributeType:NSInteger32AttributeType];
        [queuePositionAttribute setOptional:NO];
        [queuePositionAttribute setDefaultValue:[NSNumber numberWithInteger:0]];
        
        NSAttributeDescription *syncStatusAttribute = [[NSAttributeDescription alloc] init];
        [syncStatusAttribute setName:@"syncStatus"];
        [syncStatusAttribute setAttributeType:NSInteger16AttributeType];
        [syncStatusAttribute setOptional:NO];
        [syncStatusAttribute setDefaultValue:[NSNumber numberWithInteger:0]];
        
        NSAttributeDescription *primaryKeyStringAttribute = [[NSAttributeDescription alloc] init];
        [primaryKeyStringAttribute setName:@"primaryKeyString"];
        [primaryKeyStringAttribute setAttributeType:NSStringAttributeType];
        [primaryKeyStringAttribute setOptional:NO];
        [primaryKeyStringAttribute setDefaultValue:@""];
        
        NSAttributeDescription *objectIDStringAttribute = [[NSAttributeDescription alloc] init];
        [objectIDStringAttribute setName:@"objectIDString"];
        [objectIDStringAttribute setAttributeType:NSStringAttributeType];
        [objectIDStringAttribute setOptional:NO];
        [objectIDStringAttribute setDefaultValue:@""];
        
        NSAttributeDescription *classNameStringAttribute = [[NSAttributeDescription alloc] init];
        [classNameStringAttribute setName:@"className"];
        [classNameStringAttribute setAttributeType:NSStringAttributeType];
        [classNameStringAttribute setOptional:NO];
        [classNameStringAttribute setDefaultValue:@""];
        
        [syncQueue setProperties:[NSArray arrayWithObjects:queuePositionAttribute, syncStatusAttribute, primaryKeyStringAttribute, objectIDStringAttribute, classNameStringAttribute, nil]];
        
        [queuePositionAttribute release];
        [syncStatusAttribute release];
        [primaryKeyStringAttribute release];
        [objectIDStringAttribute release];
        [classNameStringAttribute release];
        
        NSEntityDescription *deletedObjectEntity = [[NSEntityDescription alloc] init];
        [deletedObjectEntity setName:@"RKDeletedObject"];
        [deletedObjectEntity setManagedObjectClassName: @"RKDeletedObject"];
        [deletedObjectEntity setAbstract:NO];
        
        NSAttributeDescription *dataAttribute = [[NSAttributeDescription alloc] init];
        [dataAttribute setName:@"data"];
        [dataAttribute setAttributeType:NSTransformableAttributeType];
        [classNameStringAttribute setOptional:YES];
        
        [deletedObjectEntity setProperties:[NSArray arrayWithObject:dataAttribute]];
        
        [dataAttribute release];
        
        [_managedObjectModel setEntities:[[_managedObjectModel entities] arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:syncQueue, deletedObjectEntity, nil]]];
        
        [syncQueue release];
        [deletedObjectEntity release];
        
        _delegate = delegate;

		[self createPersistentStoreCoordinator];

        // Ensure there is a search word observer
        [RKSearchWordObserver sharedObserver];
	}

	return self;
}

- (void)setThreadLocalObject:(id)value forKey:(id)key {
    NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
    NSString *objectStoreKey = [NSString stringWithFormat:@"RKManagedObjectStore_%p", self];
    if (! [threadDictionary valueForKey:objectStoreKey]) {
        [threadDictionary setValue:[NSMutableDictionary dictionary] forKey:objectStoreKey];
    }

    [[threadDictionary objectForKey:objectStoreKey] setObject:value forKey:key];
}

- (id)threadLocalObjectForKey:(id)key {
    NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
    NSString *objectStoreKey = [NSString stringWithFormat:@"RKManagedObjectStore_%p", self];
    if (! [threadDictionary valueForKey:objectStoreKey]) {
        [threadDictionary setObject:[NSMutableDictionary dictionary] forKey:objectStoreKey];
    }

    return [[threadDictionary objectForKey:objectStoreKey] objectForKey:key];
}

- (void)removeThreadLocalObjectForKey:(id)key {
    NSMutableDictionary* threadDictionary = [[NSThread currentThread] threadDictionary];
    NSString *objectStoreKey = [NSString stringWithFormat:@"RKManagedObjectStore_%p", self];
    if (! [threadDictionary valueForKey:objectStoreKey]) {
        [threadDictionary setObject:[NSMutableDictionary dictionary] forKey:objectStoreKey];
    }

    [[threadDictionary objectForKey:objectStoreKey] removeObjectForKey:key];
}

- (void)clearThreadLocalStorage {
    // Clear out our Thread local information
    NSManagedObjectContext *managedObjectContext = [self threadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryContextKey];
    if (managedObjectContext) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:managedObjectContext];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
        [self removeThreadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryContextKey];
    }
    if ([self threadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryEntityCacheKey]) {
        [self removeThreadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryEntityCacheKey];
    }
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [self clearThreadLocalStorage];

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
    NSError *error = nil;

	@try {
		if (![moc save:&error]) {
			if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToSaveContext:error:exception:)]) {
				[self.delegate managedObjectStore:self didFailToSaveContext:moc error:error exception:nil];
			}

			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"];
			[[NSNotificationCenter defaultCenter] postNotificationName:RKManagedObjectStoreDidFailSaveNotification object:self userInfo:userInfo];

			if ([[error domain] isEqualToString:@"NSCocoaErrorDomain"]) {
				NSDictionary *userInfo = [error userInfo];
				NSArray *errors = [userInfo valueForKey:@"NSDetailedErrors"];
				if (errors) {
					for (NSError *detailedError in errors) {
						NSDictionary *subUserInfo = [detailedError userInfo];
						RKLogError(@"Core Data Save Error\n \
							  NSLocalizedDescription:\t\t%@\n \
							  NSValidationErrorKey:\t\t\t%@\n \
							  NSValidationErrorPredicate:\t%@\n \
							  NSValidationErrorObject:\n%@\n",
							  [subUserInfo valueForKey:@"NSLocalizedDescription"], 
							  [subUserInfo valueForKey:@"NSValidationErrorKey"], 
							  [subUserInfo valueForKey:@"NSValidationErrorPredicate"], 
							  [subUserInfo valueForKey:@"NSValidationErrorObject"]);
					}
				}
				else {
					RKLogError(@"Core Data Save Error\n \
							   NSLocalizedDescription:\t\t%@\n \
							   NSValidationErrorKey:\t\t\t%@\n \
							   NSValidationErrorPredicate:\t%@\n \
							   NSValidationErrorObject:\n%@\n", 
							   [userInfo valueForKey:@"NSLocalizedDescription"],
							   [userInfo valueForKey:@"NSValidationErrorKey"], 
							   [userInfo valueForKey:@"NSValidationErrorPredicate"], 
							   [userInfo valueForKey:@"NSValidationErrorObject"]);
				}
			} 
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
	[managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];

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
        RKLogInfo(@"No existing database found, copying from seed path '%@'", seedDatabasePath);

		NSError* error;
        if (![[NSFileManager defaultManager] copyItemAtPath:seedDatabasePath toPath:self.pathToStoreFile error:&error]) {
			if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToCopySeedDatabase:error:)]) {
				[self.delegate managedObjectStore:self didFailToCopySeedDatabase:seedDatabase error:error];
			} else {
				RKLogError(@"Encountered an error during seed database copy: %@", [error localizedDescription]);
			}
        }
        NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:seedDatabasePath], @"Seed database not found at path '%@'!", seedDatabasePath);
    }
}

- (void)createPersistentStoreCoordinator {
    NSAssert(_managedObjectModel, @"Cannot create persistent store coordinator without a managed object model");
    NSAssert(!_persistentStoreCoordinator, @"Cannot create persistent store coordinator: one already exists.");
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
		} else {
			NSAssert(NO, @"Managed object store failed to create persistent store coordinator: %@", error);
		}
    }
}

- (void)deletePersistantStoreUsingSeedDatabaseName:(NSString *)seedFile {
	NSURL* storeURL = [NSURL fileURLWithPath:self.pathToStoreFile];
	NSError* error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error]) {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToDeletePersistentStore:error:)]) {
                [self.delegate managedObjectStore:self didFailToDeletePersistentStore:self.pathToStoreFile error:error];
            }
            else {
                NSAssert(NO, @"Managed object store failed to delete persistent store : %@", error);
            }
        }
    } else {
        RKLogWarning(@"Asked to delete persistent store but no store file exists at path: %@", storeURL.path);
    }

	[_persistentStoreCoordinator release];
	_persistentStoreCoordinator = nil;

	if (seedFile) {
        [self createStoreIfNecessaryUsingSeedDatabase:seedFile];
    }

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
	NSManagedObjectContext* managedObjectContext = [self threadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryContextKey];
	if (!managedObjectContext) {
		managedObjectContext = [self newManagedObjectContext];

        // Store into thread local storage dictionary
        [self setThreadLocalObject:managedObjectContext forKey:RKManagedObjectStoreThreadDictionaryContextKey];
		[managedObjectContext release];

        // If we are a background Thread MOC, we need to inform the main thread on save
        if (![NSThread isMainThread]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(mergeChanges:)
                                                         name:NSManagedObjectContextDidSaveNotification
                                                       object:managedObjectContext];
        }
	}
	return managedObjectContext;
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

- (BOOL)shouldCoerceAttributeToString:(NSString *)attribute forEntity:(NSEntityDescription *)entity {
    Class attributeType = [[RKObjectPropertyInspector sharedInspector] typeForProperty:attribute ofEntity:entity];
    return [attributeType instancesRespondToSelector:@selector(stringValue)];
}

- (void)objectsDidChange:(NSNotification*)notification {
	NSDictionary* userInfo = notification.userInfo;
	NSSet* insertedObjects = [userInfo objectForKey:NSInsertedObjectsKey];
    NSMutableDictionary* entityCache = [self threadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryEntityCacheKey];

	for (NSManagedObject* object in insertedObjects) {
		if ([object respondsToSelector:@selector(primaryKeyProperty)]) {
			Class theClass = [object class];
			NSString* primaryKey = [theClass performSelector:@selector(primaryKeyProperty)];
			id primaryKeyValue = [object valueForKey:primaryKey];
            // TODO: Unit test that this is coerced into a string!!
            NSEntityDescription *entity = [(NSManagedObject *)object entity];
            if ([self shouldCoerceAttributeToString:primaryKey forEntity:entity]) {
                primaryKeyValue = [primaryKeyValue stringValue];
            }

			NSMutableDictionary* classCache = [entityCache objectForKey:entity.name];
			if (classCache && primaryKeyValue && [classCache objectForKey:primaryKeyValue] == nil) {
				[classCache setObject:object forKey:primaryKeyValue];
			}
		}
	}
}

#pragma mark -
#pragma mark Helpers

- (NSManagedObject*)objectWithID:(NSManagedObjectID*)objectID {
    NSAssert(objectID, @"Cannot fetch a managedObject with a nil objectID");
	return [self.managedObjectContext objectWithID:objectID];
}

- (NSArray*)objectsWithIDs:(NSArray*)objectIDs {
	NSMutableArray* objects = [[NSMutableArray alloc] init];
	for (NSManagedObjectID* objectID in objectIDs) {
		[objects addObject:[self objectWithID:objectID]];
	}
	NSArray* objectArray = [NSArray arrayWithArray:objects];
	[objects release];

	return objectArray;
}

- (NSManagedObject*)findOrCreateInstanceOfEntity:(NSEntityDescription*)entity withPrimaryKeyAttribute:(NSString*)primaryKeyAttribute andValue:(id)primaryKeyValue {
    NSAssert(entity, @"Cannot instantiate managed object without a target class");
    NSAssert(primaryKeyAttribute, @"Cannot find existing managed object instance without a primary key attribute");
    NSAssert(primaryKeyValue, @"Cannot find existing managed object by primary key without a value");
	NSManagedObject* object = nil;

    // NOTE: We coerce the primary key into a string (if possible) for convenience. Generally
    // primary keys are expressed either as a number of a string, so this lets us support either case interchangeably
    id lookupValue = [primaryKeyValue respondsToSelector:@selector(stringValue)] ? [primaryKeyValue stringValue] : primaryKeyValue;
    NSArray* objectIds = nil;
    NSString* entityName = entity.name;

    if (nil == [self threadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryEntityCacheKey]) {
        [self setThreadLocalObject:[NSMutableDictionary dictionary] forKey:RKManagedObjectStoreThreadDictionaryEntityCacheKey];
    }

    // Construct the cache if necessary
    NSMutableDictionary* entityCache = [self threadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryEntityCacheKey];
    if (nil == [entityCache objectForKey:entityName]) {
        NSFetchRequest* fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
        [fetchRequest setEntity:entity];
        [fetchRequest setResultType:NSManagedObjectIDResultType];

        objectIds = [NSManagedObject executeFetchRequest:fetchRequest];
        RKLogInfo(@"Caching all %d %@ objectsIDs to thread local storage", [objectIds count], entity.name);
        NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
        if ([objectIds count] > 0) {
            BOOL coerceToString = [self shouldCoerceAttributeToString:primaryKeyAttribute forEntity:entity];
            for (NSManagedObjectID* theObjectID in objectIds) {
                NSManagedObject* theObject = [self objectWithID:theObjectID];
                id attributeValue = [theObject valueForKey:primaryKeyAttribute];
                // Coerce to a string if possible
                attributeValue = coerceToString ? [attributeValue stringValue] : attributeValue;
                if (attributeValue) {
                    [dictionary setObject:theObjectID forKey:attributeValue];
                }
            }
        }
        [entityCache setObject:dictionary forKey:entityName];
    }

    NSMutableDictionary* dictionary = [entityCache objectForKey:entityName];
    NSAssert1(dictionary, @"Thread local cache of %@ objectIDs should not be nil", entityName);
    NSManagedObjectID* objectId = [dictionary objectForKey:lookupValue];

    if (objectId == nil) {
        object = [[[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext] autorelease];

        NSError* error = nil;
        BOOL success = [self.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:object]
                                                                         error:&error];
        if (success) {
            [dictionary setObject:[object objectID] forKey:lookupValue];
        } else {
            RKLogError(@"Object store %@ was unable to obtain a permanent object ID for %@", self, object);
        }
    } else {
        object = [self objectWithID:objectId];
    }
    NSAssert(object, @"Object should not be nil");
	return object;
}

- (NSArray*)objectsForResourcePath:(NSString *)resourcePath {
    NSArray* cachedObjects = nil;

    if (self.managedObjectCache) {
        NSFetchRequest* cacheFetchRequest = [self.managedObjectCache fetchRequestForResourcePath:resourcePath];
        if (cacheFetchRequest) {
            cachedObjects = [NSManagedObject objectsWithFetchRequest:cacheFetchRequest];
        } else {
            RKLogDebug(@"Failed to find a fetchRequest for resourcePath: %@", resourcePath);
        }
    }

    return cachedObjects;
}

@end
