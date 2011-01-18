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
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kUserLoggedInNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLoginCanceledNotificationName object:nil];
}

- (void)loadView {
	[super loadView];

	// Check if we are authenticated. If not, pop in login view controller.
	if (_requiresLoggedInUser) {
		BOOL isAuthenticated = NO;
		if (_requiredUserID &&
			[DBUser currentUser].singleAccessToken &&
			// Put current user id first because it might be nil.
			[[DBUser currentUser].userID isEqualToNumber:_requiredUserID]) {
			isAuthenticated = YES;
			// TODO: Move this isAuthenticated logic into the model!
		} else if (_requiredUserID == nil &&
				   [DBUser currentUser].singleAccessToken &&
				   [DBUser currentUser] != nil) {
			isAuthenticated = YES;
		}
		if (!isAuthenticated) {
			// Register for login succeeded notification. populate view.
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogin:) name:kUserLoggedInNotificationName object:nil];
			// Register for login canceled notification. pop view controller.
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginCanceled:) name:kLoginCanceledNotificationName object:nil];
			TTOpenURL(@"db://login");
		}
	}
}

- (void)userDidLogin:(NSNotification*)note {
	// check user id is allowed.
	if (_requiredUserID && [[DBUser currentUser].userID isEqualToNumber:_requiredUserID]) {
		[self invalidateModel];
	} else {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)loginCanceled:(NSNotification*)note {
	[self.navigationController popViewControllerAnimated:YES];
}


@end
