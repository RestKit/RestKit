//
//  DBContentObject.h
//  DiscussionBoard
//
//  Created by Blake Watters on 1/20/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>
#import "DBUser.h"

// Posted when a content object has changed
extern NSString* const DBContentObjectDidChangeNotification;

/**
 * Abstract superclass for content models in the Discussion Board. Provides
 * common property & method definitions for the system
 */
@interface DBContentObject : RKManagedObject {

}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Common content properties

/**
 * A timestamp of when the object was created
 */
@property (nonatomic, retain) NSDate* createdAt;

/**
 * A timestamp of when the object was last modified
 */
@property (nonatomic, retain) NSDate* updatedAt;

/**
 * The numeric primary key of the User who created this object
 */
@property (nonatomic, retain) NSNumber* userID;

/**
 * The username of the User who created this object
 */
@property (nonatomic, readonly) NSString* username;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Common relationships

/**
 * The User who created this object within the Discussion Board.
 * This is a Core Data relationship to the User object with the
 * primary key value contained in the userID property
 */
@property (nonatomic, retain) DBUser* user;

////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns YES when the object does not have a primary key
 * for the remote system. This indicates that the object is unsaved
 */
- (BOOL)isNewRecord;

@end
