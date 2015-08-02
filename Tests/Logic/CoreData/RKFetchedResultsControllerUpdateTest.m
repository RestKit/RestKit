//
//  RKFetchedResultsControllerUpdateTest.m
//  RestKit
//
//  Created by Patrick Pierson on 4/20/15.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKHuman.h"
#import <CoreData/CoreData.h>

@interface MockFRCDelegate : NSObject <NSFetchedResultsControllerDelegate>

@property (nonatomic, copy) void (^controllerDidChangeContentBlock)();

@end

@implementation MockFRCDelegate

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (self.controllerDidChangeContentBlock) self.controllerDidChangeContentBlock();
}

@end

//--------

@interface RKFetchedResultsControllerUpdateTest : RKTestCase <NSFetchedResultsControllerDelegate>

@end

@implementation RKFetchedResultsControllerUpdateTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testFetchedResultsController
{
    //Managed object store and managed object contexts
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *persistentStoreContext = managedObjectStore.persistentStoreManagedObjectContext;
    NSManagedObjectContext *persistentStoreChild = [managedObjectStore newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType tracksChanges:NO];
    NSManagedObjectContext *mainQueueContext = managedObjectStore.mainQueueManagedObjectContext;

    //1. Create initial ManagedObjects and save to store
    [persistentStoreContext performBlockAndWait:^{
        RKHuman *human1 = [persistentStoreContext insertNewObjectForEntityForName:@"Human"];
        human1.name = @"human1";
        human1.railsID = @1;

        NSError *error = nil;
        [persistentStoreContext save:&error];
        if (error) {
            XCTAssertNil(error, @"Error: %@", error);
        }
    }];

    //2. Create NSFetchedResultsController
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Human"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:mainQueueContext sectionNameKeyPath:nil cacheName:nil];

    //3. Add delegate to detect FRC updates
    XCTestExpectation *expectation = [self expectationWithDescription:@"NSFetchedResultsController Updates"];
    MockFRCDelegate *frcDelegate = [[MockFRCDelegate alloc] init];
    frcDelegate.controllerDidChangeContentBlock = ^{
        [expectation fulfill];
    };
    fetchedResultsController.delegate = frcDelegate;
    [fetchedResultsController performFetch:nil];

    XCTAssert(fetchedResultsController.fetchedObjects.count == 1, @"Expecting NSFetchedResultsController to contain single human object.");

    //4. Update name of managed object in child managed object context
    [persistentStoreChild performBlockAndWait:^{
        NSFetchRequest *human1FetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Human"];
        NSError *error = nil;
        NSArray *results = [persistentStoreChild executeFetchRequest:human1FetchRequest error:&error];
        XCTAssertNil(error, @"Error: %@", error);

        RKHuman *childHuman1 = [results firstObject];
        XCTAssertNotNil(childHuman1, @"Failed to fetch human1");

        childHuman1.name = @"Updated Human";

        error = nil;
        [persistentStoreChild save:&error];
        if (error) {
            XCTAssertNil(error, @"Error: %@", error);
        }
    }];

    //5. Save persistent store context to store
    [persistentStoreContext performBlockAndWait:^{
        NSError *error = nil;
        [persistentStoreContext save:&error];
        XCTAssertNil(error, @"Error: %@", error);
    }];

    //6. Wait for NSFetchedResultsController update expectation
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        XCTAssertNil(error, @"Error: %@", error);
    }];

    //7. Check for new human name update in NSFetchedResultsController
    NSArray *humanNames = [fetchedResultsController.fetchedObjects valueForKeyPath:@"name"];
    XCTAssertTrue([humanNames containsObject:@"Updated Human"], @"Does not contain updated human name.");
    XCTAssertFalse([humanNames containsObject:@"human1"], @"FetchedResultsController contains original human name.");
}

@end
