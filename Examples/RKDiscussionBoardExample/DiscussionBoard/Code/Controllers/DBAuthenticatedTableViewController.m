//
//  DBAuthenticatedTableViewController.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBAuthenticatedTableViewController.h"
#import "DBUser.h"

@implementation DBAuthenticatedTableViewController

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:DBUserDidLoginNotification object:nil];
}

- (void)loadView {
	[super loadView];

	// Check if we are authenticated. If not, pop in login view controller.
	if (_requiresLoggedInUser) {
		BOOL isAuthenticated = NO;
		if (_requiredUserID &&
			[[DBUser currentUser] isLoggedIn] &&
			[[DBUser currentUser].userID isEqualToNumber:_requiredUserID]) {
			isAuthenticated = YES;
			// TODO: Move this isAuthenticated logic into the model!
		} else if (_requiredUserID == nil &&
				   [[DBUser currentUser] isLoggedIn]) {
			isAuthenticated = YES;
		}

		if (!isAuthenticated) {
			// Register for login succeeded notification. populate view.
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogin:) name:DBUserDidLoginNotification object:nil];
			
			DBLoginOrSignUpViewController* loginViewController = (DBLoginOrSignUpViewController*)TTOpenURL(@"db://login");
			loginViewController.delegate = self;
		}
	}
}

- (void)userDidLogin:(NSNotification*)note {
	// check to ensure the user that logged in is allowed to acces this controller.
	if (_requiredUserID && [[DBUser currentUser].userID isEqualToNumber:_requiredUserID]) {
		[self invalidateModel];
	} else {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)loginControllerDidCancel:(DBLoginOrSignUpViewController*)loginController {
	[self.navigationController popViewControllerAnimated:YES];
}


@end
