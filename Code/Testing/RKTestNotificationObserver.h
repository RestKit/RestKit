//
//  RKTestNotificationObserver.h
//  RestKit
//
//  Created by Jeff Arena on 8/23/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 An RKTestNotificationObserver object provides support for awaiting a notification
 to be posted as the result of an asynchronous operation by spinning the run loop. This
 enables a straight-forward unit testing workflow by blocking execution of the test until
 a notification is posted.
 */
@interface RKTestNotificationObserver : NSObject

/**
 The name of the notification the receiver is awaiting.
 */
@property (nonatomic, copy) NSString *name;

/**
 The object expected to post the notification the receiver is awaiting.

 Can be nil.
 */
@property (nonatomic, assign) id object;

/**
 The timeout interval, in seconds, to wait for the notification to be posted.

 **Default**: 3 seconds
 */
@property (nonatomic, assign) NSTimeInterval timeout;

/**
 Creates and initializes a notification obsercer object.

 @return The newly created notification observer.
 */
+ (RKTestNotificationObserver *)notificationObserver;

/**
 Instantiate a notification observer for the given notification name and object

 @param notificationName The name of the NSNotification we want to watch for
 @param notificationSender The source object of the NSNotification we want to watch for
 @return The newly created notification observer initialized with notificationName and notificationSender.
 */
+ (RKTestNotificationObserver *)notificationObserverForName:(NSString *)notificationName object:(id)notificationSender;

/**
 Instantiate a notification observer for the given notification name

 @param notificationName The name of the NSNotification we want to watch for
 */
+ (RKTestNotificationObserver *)notificationObserverForName:(NSString *)notificationName;

/**
 Wait for a notification matching the name and source object we are observing to be posted.

 This method will block by spinning the runloop waiting for an appropriate notification matching
 our observed name and object to be posted or the timeout configured is exceeded.
 */
- (void)waitForNotification;

/*** @name Block Helpers */

/**
 Configures a notification observer to wait for the a notification with the given name to be posted
 by the source object during execution of the block.

 @param name The name of the notification we are waiting for
 @param notificationSender The object we are waiting to post the notification
 @param block A block to invoke to trigger the notification activity
 */
+ (void)waitForNotificationWithName:(NSString *)name object:(id)notificationSender usingBlock:(void(^)())block;

/**
 Configures a notification observer to wait for the a notification with the given name to be posted
 during execution of the block.

 @param name The name of the notification we are waiting for
 @param block A block to invoke to trigger the notification activity
 */
+ (void)waitForNotificationWithName:(NSString *)name usingBlock:(void(^)())block;

@end
