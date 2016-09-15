//
//  RKTwitterAppDelegate.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>
#import "RKTwitterAppDelegate.h"
#import "RKTwitterViewController.h"
#import "RKTweet.h"

@implementation RKTwitterAppDelegate

@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize RestKit
    NSURL *baseURL = [NSURL URLWithString:@"https://twitter.com"];
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:baseURL];
    
    // HACK: Set User-Agent to Mac OS X so that Twitter will let us access the Timeline
    [objectManager.HTTPClient setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]]];

    // Enable Activity Indicator Spinner
    [AFRKNetworkActivityIndicatorManager sharedManager].enabled = YES;

    // Initialize managed object store
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    objectManager.managedObjectStore = managedObjectStore;

    // Setup our object mappings
    /**
     Mapping by entity. Here we are configuring a mapping by targetting a Core Data entity with a specific
     name. This allows us to map back Twitter user objects directly onto NSManagedObject instances --
     there is no backing model class!
     */
    RKEntityMapping *userMapping = [RKEntityMapping mappingForEntityForName:@"User" inManagedObjectStore:managedObjectStore];
    userMapping.identificationAttributes = @[ @"userID" ];
    [userMapping addAttributeMappingsFromDictionary:@{
     @"id": @"userID",
     @"screen_name": @"screenName",
    }];
    // If source and destination key path are the same, we can simply add a string to the array
    [userMapping addAttributeMappingsFromArray:@[ @"name" ]];

    RKEntityMapping *tweetMapping = [RKEntityMapping mappingForEntityForName:@"Tweet" inManagedObjectStore:managedObjectStore];
    tweetMapping.identificationAttributes = @[ @"statusID" ];
    [tweetMapping addAttributeMappingsFromDictionary:@{
     @"id": @"statusID",
     @"created_at": @"createdAt",
     @"text": @"text",
     @"url": @"urlString",
     @"in_reply_to_screen_name": @"inReplyToScreenName",
     @"favorited": @"isFavorited",
     }];
    [tweetMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"user" toKeyPath:@"user" withMapping:userMapping]];

    // Update date format so that we can parse Twitter dates properly
    // Wed Sep 29 15:31:08 +0000 2010
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"E MMM d HH:mm:ss Z y";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    [[RKValueTransformer defaultValueTransformer] insertValueTransformer:dateFormatter atIndex:0];

    // Register our mappings with the provider
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:tweetMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"/status/user_timeline/:username"
                                                                                           keyPath:nil
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [objectManager addResponseDescriptor:responseDescriptor];

    // Uncomment this to use XML, comment it to use JSON
    //  objectManager.acceptMIMEType = RKMIMETypeXML;
    //  [objectManager.mappingProvider setMapping:statusMapping forKeyPath:@"statuses.status"];
    
    // Database seeding is configured as a copied target of the main application. There are only two differences
    // between the main application target and the 'Generate Seed Database' target:
    //  1) RESTKIT_GENERATE_SEED_DB is defined in the 'Preprocessor Macros' section of the build setting for the target
    //      This is what triggers the conditional compilation to cause the seed database to be built
    //  2) Source JSON files are added to the 'Generate Seed Database' target to be copied into the bundle. This is required
    //      so that the object seeder can find the files when run in the simulator.    
#ifdef RESTKIT_GENERATE_SEED_DB
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelInfo);
    RKLogConfigureByName("RestKit/CoreData", RKLogLevelTrace);
    
    NSError *error = nil;
    BOOL success = RKEnsureDirectoryExistsAtPath(RKApplicationDataDirectory(), &error);
    if (! success) {
        RKLogError(@"Failed to create Application Data Directory at path '%@': %@", RKApplicationDataDirectory(), error);
    }
    NSString *seedStorePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"RKSeedDatabase.sqlite"];
    RKManagedObjectImporter *importer = [[RKManagedObjectImporter alloc] initWithManagedObjectModel:managedObjectModel storePath:seedStorePath];
    [importer importObjectsFromItemAtPath:[[NSBundle mainBundle] pathForResource:@"restkit" ofType:@"json"]
                              withMapping:tweetMapping
                                  keyPath:nil
                                    error:&error];
    [importer importObjectsFromItemAtPath:[[NSBundle mainBundle] pathForResource:@"users" ofType:@"json"]
                              withMapping:userMapping
                                  keyPath:@"user"
                                    error:&error];
    success = [importer finishImporting:&error];
    if (success) {
        [importer logSeedingInfo];
    } else {
        RKLogError(@"Failed to finish import and save seed database due to error: %@", error);
    }

    // Clear out the root view controller
    [self.window setRootViewController:[UIViewController new]];
#else
    /**
     Complete Core Data stack initialization
     */
    [managedObjectStore createPersistentStoreCoordinator];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"RKTwitter.sqlite"];
    NSString *seedPath = [[NSBundle mainBundle] pathForResource:@"RKSeedDatabase" ofType:@"sqlite"];
    NSError *error;
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:seedPath withConfiguration:nil options:nil error:&error];
    NSAssert(persistentStore, @"Failed to add persistent store with error: %@", error);
    
    // Create the managed object contexts
    [managedObjectStore createManagedObjectContexts];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
#endif

    return YES;
}

@end
