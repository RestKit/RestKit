//
//  DBUser.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBUser.h"

@implementation DBUser

@dynamic email;
@dynamic login;
@dynamic singleAccessToken;
@dynamic userID;

@synthesize password = _password;
@synthesize passwordConfirmation = _passwordConfirmation;

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"id", @"userID",
			@"email", @"email",
			@"login", @"login",
			@"single_access_token", @"singleAccessToken",
			@"password", @"password",
			@"password_confirmation", @"passwordConfirmation",
			nil];
}

+ (NSString*)primaryKeyProperty {
	return @"userID";
}

+ (DBUser*)currentUser {
	id	userID = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentUserIDKey];
	return [self objectWithPrimaryKeyValue:userID];
}

+ (void)logout {
	[[NSUserDefaults standardUserDefaults] setValue:nil forKey:kCurrentUserIDKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedOutNotificationName object:nil];
}

- (void)dealloc {
	[_password release];
	[_passwordConfirmation release];
	[super dealloc];
}

- (NSObject<RKRequestSerializable>*)paramsForSerialization {
	if (_passwordConfirmation) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				self.email, @"user[email]",
				self.login, @"user[login]",
				self.password, @"user[password]",
				self.passwordConfirmation, @"user[password_confirmation]", nil];
	}
	return [NSDictionary dictionaryWithObjectsAndKeys:
			self.login, @"user[login]",
			self.password, @"user[password]", nil];
}

@end
