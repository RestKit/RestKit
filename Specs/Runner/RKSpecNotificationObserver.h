//
//  RKSpecNotificationObserver.h
//  RestKit
//
//  Created by Jeff Arena on 8/23/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 A testing helper for observing notifications with a timeout
 */
@interface RKSpecNotificationObserver : NSObject {
    NSString *_name;
    id object;    
    BOOL _awaitingResponse;
	NSTimeInterval _timeout;
}

/// The notification we are observing
@property (nonatomic, copy)   NSString* name;

/// The object we are observing
@property (nonatomic, assign) id object;

/**
 The timeout interval to wait for the notification
 
 **Default**: 3 seconds
 */
@property (nonatomic, assign) NSTimeInterval timeout;

/**
 Instantiate a notification observer
 */
+ (RKSpecNotificationObserver *)notificationObserver;

/**
 Instantiate a notification observer for the given notification name and object
 
 @param notificationName The name of the NSNotification we want to watch for
 @param object The source object of the NSNotification we want to watch for
 */
+ (RKSpecNotificationObserver *)notificationObserverForName:(NSString *)notificationName object:(id)object;

/**
 Instantiate a notification observer for the given notification name
 
 @param notificationName The name of the NSNotification we want to watch for
 */
+ (RKSpecNotificationObserver *)notificationObserverForName:(NSString *)notificationName;

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
 @param object The object we are waiting to post the notification
 @param block A block to invoke to trigger the notification activity
 */
+ (void)waitForNotificationWithName:(NSString *)name object:(id)object usingBlock:(void(^)())block;

/**
 Configures a notification observer to wait for the a notification with the given name to be posted
 during execution of the block.
 
 @param name The name of the notification we are waiting for
 @param block A block to invoke to trigger the notification activity
 */
+ (void)waitForNotificationWithName:(NSString *)name usingBlock:(void(^)())block;

@end
