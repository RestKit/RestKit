//
//  RKTStatus.h
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData.h>

@interface RKTStatus : NSManagedObject {
}

/**
 * The unique ID of this Status
 */
@property (nonatomic, retain) NSNumber *statusID;

/**
 * Timestamp the Status was sent
 */
@property (nonatomic, retain) NSDate *createdAt;

/**
 * Text of the Status
 */
@property (nonatomic, retain) NSString *text;

/**
 * String version of the URL associated with the Status
 */
@property (nonatomic, retain) NSString *urlString;

/**
 * The screen name of the User this Status was in response to
 */
@property (nonatomic, retain) NSString *inReplyToScreenName;

/**
 * Is this status a favorite?
 */
@property (nonatomic, assign) BOOL isFavorited;

/**
 * The User who posted this status
 */
@property (nonatomic, retain) NSManagedObject *user;

@end
