//
//  DBLoginOrSignUpViewController.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBLoginOrSignUpViewController.h"

@implementation DBLoginOrSignUpViewController

@synthesize delegate = _delegate;

- (id)initWithNavigatorURL:(NSURL *)URL query:(NSDictionary *)query {
	if (self = [super initWithNavigatorURL:URL query:query]) {
		self.title = @"Login";
		self.autoresizesForKeyboard = YES;
		self.tableViewStyle = UITableViewStyleGrouped;
	}
	
	return self;
}

- (void)viewDidUnload {
	// Resign as the delegate
	if ([DBUser currentUser].delegate == self) {
		[DBUser currentUser].delegate = nil;
	}
	
	TT_RELEASE_SAFELY(_signupOrLoginButtonItem);
	TT_RELEASE_SAFELY(_usernameField);
	TT_RELEASE_SAFELY(_passwordField);
	TT_RELEASE_SAFELY(_passwordConfirmationField);
	TT_RELEASE_SAFELY(_emailField);
}

- (void)loadView {
	[super loadView];

	UIBarButtonItem* cancelItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
																   style:UIBarButtonItemStyleBordered
																  target:self
																   action:@selector(cancelButtonWasPressed:)] autorelease];
	self.navigationItem.leftBarButtonItem = cancelItem;

	_signupOrLoginButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Signup"
																style:UIBarButtonItemStyleBordered
															   target:self
															   action:@selector(signupOrLoginButtonItemWasPressed:)];
	_showingSignup = NO;
	self.navigationItem.rightBarButtonItem = _signupOrLoginButtonItem;

	_usernameField = [[UITextField alloc] initWithFrame:CGRectZero];
	_usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	_usernameField.delegate = self;
	_usernameField.returnKeyType = UIReturnKeyNext;

	_passwordField = [[UITextField alloc] initWithFrame:CGRectZero];
	[_passwordField setSecureTextEntry:YES];
	_passwordField.delegate = self;

	_passwordConfirmationField = [[UITextField alloc] initWithFrame:CGRectZero];
	[_passwordConfirmationField setSecureTextEntry:YES];
	_passwordConfirmationField.delegate = self;
	_passwordConfirmationField.returnKeyType = UIReturnKeyGo;

	_emailField = [[UITextField alloc] initWithFrame:CGRectZero];
	_emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	_emailField.delegate = self;
	_emailField.returnKeyType = UIReturnKeyNext;
}

- (void)createModel {
	NSMutableArray* items = [NSMutableArray array];
	if (_showingSignup) {
		[items addObject:[TTTableControlItem itemWithCaption:@"Username" control:_usernameField]];
		[items addObject:[TTTableControlItem itemWithCaption:@"Email" control:_emailField]];
		[items addObject:[TTTableControlItem itemWithCaption:@"Password" control:_passwordField]];
		[items addObject:[TTTableControlItem itemWithCaption:@"Confirm" control:_passwordConfirmationField]];
		_passwordField.returnKeyType = UIReturnKeyNext;
	} else {
		[items addObject:[TTTableControlItem itemWithCaption:@"Username" control:_usernameField]];
		[items addObject:[TTTableControlItem itemWithCaption:@"Password" control:_passwordField]];
		_passwordField.returnKeyType = UIReturnKeyGo;
	}
	self.dataSource = [TTListDataSource dataSourceWithItems:items];

	[_usernameField becomeFirstResponder];
}

- (void)cancelButtonWasPressed:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
	[_delegate loginControllerDidCancel:self];
}

- (void)signupOrLoginButtonItemWasPressed:(id)sender {
	if (_showingSignup) {
		_showingSignup = NO;
		[_signupOrLoginButtonItem setTitle:@"Login"];
	} else {
		_showingSignup = YES;
		[_signupOrLoginButtonItem setTitle:@"Signup"];
	}
	[self invalidateModel];
}

- (void)loginOrSignup {
	if (_showingSignup) {
		// Signup
		DBUser* user = [DBUser object];
		user.username = _usernameField.text;
		user.email = _emailField.text;
		user.password = _passwordField.text;
		user.passwordConfirmation = _passwordConfirmationField.text;
		[user signUpWithDelegate:self];
	} else {
		// Login
		DBUser* user = [DBUser object];		
		user.delegate = self;
		[user loginWithUsername:_usernameField.text andPassword:_passwordField.text delegate:self];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == _usernameField) {
		if (_showingSignup) {
			[_emailField becomeFirstResponder];
		} else {
			[_passwordField becomeFirstResponder];
		}
	} else if (textField == _passwordField) {
		if (_showingSignup) {
			[_passwordConfirmationField becomeFirstResponder];
		} else {
			[self loginOrSignup];
		}
	} else if (textField == _emailField) {
		[_passwordField becomeFirstResponder];
	} else if (textField == _passwordConfirmationField) {
		[self loginOrSignup];
	}
	
	return NO;
}

#pragma mark DBUserAuthenticationDelegate methods

- (void)userDidLogin:(DBUser*)user {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)user:(DBUser*)user didFailSignUpWithError:(NSError*)error {	
	TTAlert([error localizedDescription]);
}

- (void)user:(DBUser*)user didFailLoginWithError:(NSError*)error {
	[[[[UIAlertView alloc] initWithTitle:@"Error"
								 message:[error localizedDescription]
								delegate:nil
					   cancelButtonTitle:@"OK"
					   otherButtonTitles:nil] autorelease] show];
}

@end
