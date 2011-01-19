//
//  DBUser.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBUser.h"

// Constants
static NSString* const kDBUserCurrentUserIDDefaultsKey = @"kDBUserCurrentUserIDDefaultsKey";

// Notifications
NSString* const DBUserDidLoginNotification = @"DBUserDidLoginNotification";
NSString* const DBUserDidFailLoginNotification = @"DBUserDidFailLoginNotification";
NSString* const DBUserDidLogoutNotification = @"DBUserDidLogoutNotification";

@implementation DBUser

@dynamic email;
@dynamic username;
@dynamic singleAccessToken;
@dynamic userID;
@synthesize password = _password;
@synthesize passwordConfirmation = _passwordConfirmation;
@synthesize delegate = _delegate;

/**
 * The property mapping dictionary. This method declares how elements in the JSON
 * are mapped to properties on the object
 */
+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"id", @"userID",
			@"email", @"email",
			@"username", @"login",
			@"single_access_token", @"singleAccessToken",
			@"password", @"password",
			@"password_confirmation", @"passwordConfirmation",
			nil];
}

/**
 * Informs RestKit which property contains the primary key for identifying
 * this object. This is used to ensure that existing objects are updated during mapping
 */
+ (NSString*)primaryKeyProperty {
	return @"userID";
}

/**
 * Returns the singleton current User instance. There is always a User returned so that you
 * are not sending messages to nil
 */
+ (DBUser*)currentUser {
	id userID = [[NSUserDefaults standardUserDefaults] objectForKey:kDBUserCurrentUserIDDefaultsKey];
	if (userID) {
		return [self objectWithPrimaryKeyValue:userID];
	} else {
		return [self object];
	}
}

/**
 * Implementation of a RESTful login pattern. We construct an object loader addressed to
 * the /login resource path and POST the credentials. The target of the object loader is
 * set so that the login request
 *
 */
- (void)loginWithUsername:(NSString*)username andPassword:(NSString*)password {
	RKObjectLoader* objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:@"/login" delegate:self];
	objectLoader.method = RKRequestMethodPOST;
	objectLoader.params = [NSDictionary dictionaryWithKeysAndObjects:@"username", username, @"password", password, nil];
	objectLoader.targetObject = self;
	[objectLoader send];
}

/**
 * Implementation of a RESTful logout pattern. We POST an object loader to
 * the /logout resource path. This destroys the remote session
 */
- (void)logout {
	RKObjectLoader* objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:@"/logout" delegate:self];
	objectLoader.method = RKRequestMethodPOST;
	objectLoader.targetObject = self; // TODO: Not sure I need this?
	[objectLoader send];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects {
	DBUser* user = [objects objectAtIndex:0];

	if ([objectLoader wasSentToResourcePath:@"/login"]) {
		// Login was successful

		// Persist the UserID for recovery later
		[[NSUserDefaults standardUserDefaults] setObject:user.userID forKey:kDBUserCurrentUserIDDefaultsKey];
		[[NSUserDefaults standardUserDefaults] synchronize];

		// Inform the delegate
		if ([self.delegate respondsToSelector:@selector(userDidLogin:)]) {
			[self.delegate userDidLogin:self];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:DBUserDidLoginNotification object:user];
	} else if ([objectLoader wasSentToResourcePath:@"/logout"]) {
		// Logout was successful

		// Clear the stored credentials
		[[NSUserDefaults standardUserDefaults] setValue:nil forKey:kDBUserCurrentUserIDDefaultsKey];
		[[NSUserDefaults standardUserDefaults] synchronize];

		// Inform the delegate
		if ([self.delegate respondsToSelector:@selector(userDidLogout:)]) {
			[self.delegate userDidLogout:self];
		}

		[[NSNotificationCenter defaultCenter] postNotificationName:DBUserDidLogoutNotification object:nil];
	}
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError*)error {
	// Login failed
	if ([objectLoader wasSentToResourcePath:@"/login"]) {
		if ([self.delegate respondsToSelector:@selector(user:didFailLoginWithError:)]) {
			[self.delegate user:self didFailLoginWithError:error];
		}
	}
}

// TODO: Do I need this?
- (void)reauthenticate {
}

- (BOOL)isLoggedIn {
	return self.singleAccessToken != nil;
}

// TODO: Do I need this?
//- (NSObject<RKRequestSerializable>*)paramsForSerialization {
//	if (_passwordConfirmation) {
//		return [NSDictionary dictionaryWithObjectsAndKeys:
//				self.email, @"user[email]",
//				self.login, @"user[login]",
//				self.password, @"user[password]",
//				self.passwordConfirmation, @"user[password_confirmation]", nil];
//	} else {
//		return [NSDictionary dictionaryWithObjectsAndKeys:
//				self.login, @"user[login]",
//				self.password, @"user[password]", nil];
//	}
//}

- (void)dealloc {
	[_password release];
	[_passwordConfirmation release];
	[super dealloc];
}

@end
