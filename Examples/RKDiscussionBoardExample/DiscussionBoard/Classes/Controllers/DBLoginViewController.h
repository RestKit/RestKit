//
//  DBLoginViewController.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Three20/Three20.h>
#import <Three20/Three20+Additions.h>
#import <RestKit/RestKit.h>

@interface DBLoginViewController : TTTableViewController <UITextFieldDelegate, RKObjectLoaderDelegate> {
	UIBarButtonItem* _signupOrLoginButtonItem;
	BOOL _showingSignup;
	
	UITextField* _usernameField;
	UITextField* _passwordField;
	UITextField* _passwordConfirmationField;
	UITextField* _emailField;
}

@end
