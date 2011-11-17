//
//  RKTableViewExampleAppDelegate.h
//  RKTableViewExample
//
//  Created by Blake Watters on 8/2/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RKTableViewExampleAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
