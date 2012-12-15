//
//  RKTweet.h
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTUser.h"

@interface RKTweet : NSObject

/**
 * The unique ID of this Status
 */
@property (nonatomic, copy) NSNumber *statusID;

/**
 * Timestamp the Status was sent
 */
@property (nonatomic, copy) NSDate *createdAt;

/**
 * Text of the Status
 */
@property (nonatomic, copy) NSString *text;

/**
 * String version of the URL associated with the Status
 */
@property (nonatomic, copy) NSString *urlString;

/**
 * The screen name of the User this Status was in response to
 */
@property (nonatomic, copy) NSString *inReplyToScreenName;

/**
 * Is this status a favorite?
 */
@property (nonatomic, copy) NSNumber *isFavorited;

/**
 * The User who posted this status
 */
@property (nonatomic, strong) RKTUser *user;

@end
