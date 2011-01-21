//
//  DBAuthenticatedTableViewController.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import "DBUser.h"
#import "DBLoginOrSignUpViewController.h"

@interface DBAuthenticatedTableViewController : TTTableViewController <DBLoginOrSignupViewControllerDelegate> {
	DBUser* _requiredUser;
}

/**
 * The User who we must be logged in as to edit the specified content
 */
@property (nonatomic, retain) DBUser* requiredUser;

/**
 * Presents the Login controller if the current User is not authenticated
 */
- (void)presentLoginViewControllerIfNecessary;

@end
