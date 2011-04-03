//
//  RKTwitterAppDelegate.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright Two Toasters 2010. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>
#import "RKTwitterAppDelegate.h"
#import "RKTwitterViewController.h"
#import "RKTStatus.h"
#import "RKTUser.h"

@implementation RKTwitterAppDelegate

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize RestKit
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:@"http://twitter.com"];
	RKObjectMapper* mapper = objectManager.mapper;	    
    
    // Update date format so that we can parse twitter dates properly
	// Wed Sep 29 15:31:08 +0000 2010
	NSMutableArray* dateFormats = [[[mapper dateFormats] mutableCopy] autorelease];
	[dateFormats addObject:@"E MMM d HH:mm:ss Z y"];
	[mapper setDateFormats:dateFormats];
	
	// Add our element to object mappings
	[mapper registerClass:[RKTUser class] forElementNamed:@"user"];
	[mapper registerClass:[RKTStatus class] forElementNamed:@"status"];
    
    // Database seeding is configured as a copied target of the main application. There are only two differences
    // between the main application target and the 'Generate Seed Database' target:
    //  1) RESTKIT_GENERATE_SEED_DB is defined in the 'Preprocessor Macros' section of the build setting for the target
    //      This is what triggers the conditional compilation to cause the seed database to be built
    //  2) Source JSON files are added to the 'Generate Seed Database' target to be copied into the bundle. This is required
    //      so that the object seeder can find the files when run in the simulator.
#ifdef RESTKIT_GENERATE_SEED_DB    
    RKManagedObjectSeeder* seeder = [RKManagedObjectSeeder objectSeederWithObjectManager:objectManager];
    
    // Seed the database with instances of RKTStatus from a snapshot of the RestKit Twitter timeline
    [seeder seedObjectsFromFile:@"restkit.json" toClass:[RKTStatus class] keyPath:nil];
    
    // Seed the database with RKTUser objects. The class will be inferred via element registration
    [seeder seedObjectsFromFiles:@"users.json", nil];
    
    // Finalize the seeding operation and output a helpful informational message
    [seeder finalizeSeedingAndExit];
    
    // NOTE: If all of your mapped objects use element -> class registration, you can perform seeding in one line of code:
    // [RKManagedObjectSeeder generateSeedDatabaseWithObjectManager:objectManager fromFiles:@"users.json", nil];
#endif
    
    // Initialize object store
    objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKTwitterData.sqlite" usingSeedDatabaseName:RKDefaultSeedDatabaseFileName managedObjectModel:nil];
    
    // Create Window and View Controllers
	RKTwitterViewController* viewController = [[[RKTwitterViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	UINavigationController* controller = [[UINavigationController alloc] initWithRootViewController:viewController];
	UIWindow* window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [window addSubview:controller.view];
    [window makeKeyAndVisible];

    return YES;
}

- (void)dealloc {
    [super dealloc];
}


@end
