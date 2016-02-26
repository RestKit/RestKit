//
//  RKSAppDelegate.h
//  RKSearchExample
//
//  Created by Blake Watters on 8/7/12.
//  Copyright (c) 2012 Blake Watters. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/RestKit.h>

@interface RKSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RKManagedObjectStore *managedObjectStore;

@end
