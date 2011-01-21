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

@synthesize requiredUser = _requiredUser;

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:DBUserDidLoginNotification object:nil];
}

- (void)presentLoginViewControllerIfNecessary {
	if (NO == [[DBUser currentUser] isLoggedIn]) {
		// Register for login succeeded notification. populate view.
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogin:) name:DBUserDidLoginNotification object:nil];
		
		DBLoginOrSignUpViewController* loginViewController = (DBLoginOrSignUpViewController*) TTOpenURL(@"db://login");
		loginViewController.delegate = self;
	}
}

- (void)userDidLogin:(NSNotification*)note {
	// Check to ensure the User who logged in is allowed to access this controller.
	if ([[DBUser currentUser] isEqual:self.requiredUser]) {
		[self invalidateModel];
	} else {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void)loginControllerDidCancel:(DBLoginOrSignUpViewController*)loginController {
	[self.navigationController popViewControllerAnimated:YES];
}

@end
