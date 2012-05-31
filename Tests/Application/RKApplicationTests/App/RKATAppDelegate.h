//
//  RKATAppDelegate.h
//  RKApplicationTests
//
//  Created by Blake Watters on 2/8/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RKATAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
