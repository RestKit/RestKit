//
//  DBUser.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBUser.h"
#import "DBContentObject.h"

// Constants
static NSString* const kDBUserCurrentUserIDDefaultsKey = @"kDBUserCurrentUserIDDefaultsKey";

// Notifications
NSString* const DBUserDidLoginNotification = @"DBUserDidLoginNotification";
NSString* const DBUserDidFailLoginNotification = @"DBUserDidFailLoginNotification";
NSString* const DBUserDidLogoutNotification = @"DBUserDidLogoutNotification";

// Current User singleton
static DBUser* currentUser = nil;

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
			@"username", @"username",
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
	if (nil == currentUser) {
		id userID = [[NSUserDefaults standardUserDefaults] objectForKey:kDBUserCurrentUserIDDefaultsKey];
		if (userID) {
			currentUser = [self objectWithPrimaryKeyValue:userID];
		} else {
			currentUser = [self object];
		}
		
		[currentUser retain];
	}
	
	return currentUser;
}

+ (void)setCurrentUser:(DBUser*)user {
	[user retain];
	[currentUser release];
	currentUser = user;
}

/**
 * Implementation of a RESTful sign-up pattern. We are just relying on RestKit for
 * request/response processing and object mapping, but we have built a higher level
 * abstraction around Sign-Up as a concept and exposed notifications and delegate
 * methods that make it much more meaningful than a POST/parse/process cycle would be.
 */
- (void)signUpWithDelegate:(NSObject<DBUserAuthenticationDelegate>*)delegate {
	_delegate = delegate;
	[[RKObjectManager sharedManager] postObject:self delegate:self];
}

/**
 * Implementation of a RESTful login pattern. We construct an object loader addressed to
 * the /login resource path and POST the credentials. The target of the object loader is
 * set so that the login response gets mapped back into this object, populating the
 * properties according to the mappings declared in elementToPropertyMappings.
 */
- (void)loginWithUsername:(NSString*)username andPassword:(NSString*)password delegate:(NSObject<DBUserAuthenticationDelegate>*)delegate {
	_delegate = delegate;
	
	RKObjectLoader* objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:@"/login" delegate:self];
	objectLoader.method = RKRequestMethodPOST;
	objectLoader.params = [NSDictionary dictionaryWithKeysAndObjects:@"user[username]", username, @"user[password]", password, nil];	
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
	objectLoader.targetObject = self;
	[objectLoader send];
}

- (void)loginWasSuccessful {
	// Upon login, we become the current user
	[DBUser setCurrentUser:self];
	
	// Persist the UserID for recovery later
	[[NSUserDefaults standardUserDefaults] setObject:self.userID forKey:kDBUserCurrentUserIDDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// Inform the delegate
	if ([self.delegate respondsToSelector:@selector(userDidLogin:)]) {
		[self.delegate userDidLogin:self];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DBUserDidLoginNotification object:self];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects {
	// NOTE: We don't need objects because self is the target of the mapping operation
	
	if ([objectLoader wasSentToResourcePath:@"/login"]) {
		// Login was successful
		[self loginWasSuccessful];
	} else if ([objectLoader wasSentToResourcePath:@"/signup"]) { 
		// Sign Up was successful
		if ([self.delegate respondsToSelector:@selector(userDidSignUp:)]) {
			[self.delegate userDidSignUp:self];
		}
		
		// Complete the login as well
		[self loginWasSuccessful];		
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
	if ([objectLoader wasSentToResourcePath:@"/login"]) {
		// Login failed
		if ([self.delegate respondsToSelector:@selector(user:didFailLoginWithError:)]) {
			[self.delegate user:self didFailLoginWithError:error];
		}
	} else if ([objectLoader wasSentToResourcePath:@"/signup"]) {
		// Sign Up failed
		if ([self.delegate respondsToSelector:@selector(user:didFailSignUpWithError:)]) {
			[self.delegate user:self didFailSignUpWithError:error];
		}
	}
}

- (BOOL)isLoggedIn {
	return self.singleAccessToken != nil;
}

- (BOOL)canModifyObject:(DBContentObject*)object {
	if ([object isNewRecord]) {
		return YES;
	} else if ([self isLoggedIn] && [self isEqual:object.user]) {
		return YES;
	} else {
		return NO;
	}
}

- (void)dealloc {
	_delegate = nil;
	[_password release];
	[_passwordConfirmation release];
	[super dealloc];
}

@end
