//
//  DBLoginOrSignUpViewController.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import <Three20/Three20+Additions.h>
#import <RestKit/RestKit.h>
#import "DBUser.h"

@protocol DBLoginOrSignupViewControllerDelegate;


@interface DBLoginOrSignUpViewController : TTTableViewController <UITextFieldDelegate, DBUserAuthenticationDelegate> {
	UIBarButtonItem* _signupOrLoginButtonItem;
	BOOL _showingSignup;

	UITextField* _usernameField;
	UITextField* _passwordField;
	UITextField* _passwordConfirmationField;
	UITextField* _emailField;
	
	id<DBLoginOrSignupViewControllerDelegate> _delegate;
}

@property (nonatomic, assign) id<DBLoginOrSignupViewControllerDelegate> delegate;


@end

@protocol DBLoginOrSignupViewControllerDelegate

- (void)loginControllerDidCancel:(DBLoginOrSignUpViewController*)loginController;

@end
