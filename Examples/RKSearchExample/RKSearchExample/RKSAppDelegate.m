//
//  RKSAppDelegate.m
//  RKSearchExample
//
//  Created by Blake Watters on 8/7/12.
//  Copyright (c) 2012 Blake Watters. All rights reserved.
//

#import <RestKit/Search.h>
#import "RKSAppDelegate.h"

@implementation RKSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Turn on logging for the Search component
    RKLogConfigureByName("RestKit/Search", RKLogLevelTrace);
    
    // Initialize the managed object store
    // NOTE: To add search indexing an entity, the managed object model must be mutable. The `mergedModelFromBundles:` method returns an immutable model, so we must send a `mutableCopy` message to obtain a model that we can add indexing to.
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] mutableCopy];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    
    // Configure the Contact entity for mapping
    RKEntityMapping *contactMapping = [RKEntityMapping mappingForEntityForName:@"Contact" inManagedObjectStore:managedObjectStore];
    [contactMapping addAttributeMappingsFromDictionary:@{
     @"first_name" : @"firstName",
     @"last_name": @"lastName",
     @"email_adddress": @"emailAddress",
     @"phone_number": @"phoneNumber",
     @"notes": @"notes"
     }];
    
    // Configure search indexing
    [managedObjectStore addSearchIndexingToEntityForName:@"Contact"
                                            onAttributes:@[ @"firstName", @"lastName", @"emailAddress", @"phoneNumber", @"notes"]];
    
    // Finalize Core Data initialization
    NSError *error = nil;
    NSPersistentStore *persistentStore = [managedObjectStore addInMemoryPersistentStore:&error];
    NSAssert(persistentStore, @"Failed to create persistent store: %@", error);
    [managedObjectStore createManagedObjectContexts];
    
    // Import searchable content from a JSON file
    RKManagedObjectImporter *importer = [[RKManagedObjectImporter alloc] initWithPersistentStore:persistentStore];
    NSString *pathToDataFile = [[NSBundle mainBundle] pathForResource:@"contacts" ofType:@"json"];
    NSUInteger count = [importer importObjectsFromItemAtPath:pathToDataFile withMapping:contactMapping keyPath:@"contacts" error:&error];
    NSAssert(count != NSNotFound, @"Failed to import contacts at path '%@': %@", pathToDataFile, error);
    
    // Index the imported objects
    [managedObjectStore.searchIndexer indexChangedObjectsInManagedObjectContext:importer.managedObjectContext waitUntilFinished:YES];
    BOOL success = [importer finishImporting:&error];
    NSAssert(success, @"Failed to finish import operation: %@", error);
    
    self.managedObjectStore = managedObjectStore;
    
    return YES;
}

@end
