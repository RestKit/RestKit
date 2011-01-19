//
//  DBUser.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>

// Declared here and defined below
@protocol DBUserDelegate;

////////////////////////////////////////////////////////////////////////////////////////////////

@interface DBUser : RKManagedObject <RKObjectLoaderDelegate> {
	// Transient. Used for login & sign-up
	NSString* _password;
	NSString* _passwordConfirmation;
	NSObject<DBUserDelegate>* _delegate;
}

/**
 * The delegate for the User. Will be informed of session life-cycle events
 */
@property (nonatomic, retain) NSObject<DBUserDelegate>* delegate;

/**
 * The e-mail address of the User
 */
@property (nonatomic, retain) NSString* email;

/**
 * The username of the User
 */
@property (nonatomic, retain) NSString* username;

/**
 * An Access Token returned when a User is authenticated
 */
@property (nonatomic, retain) NSString* singleAccessToken;

/**
 * The numeric primary key of this User in the remote backend system
 */
@property (nonatomic, retain) NSNumber* userID;

#pragma mark Transient sign-up properties

/**
 * The password the User wants to secure their account with
 */
@property (nonatomic, retain) NSString* password;

/**
 * A confirmation of the password the User wants t secure their account with
 */
@property (nonatomic, retain) NSString* passwordConfirmation;

////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * A globally available singleton reference to the current User. When the User is
 * not authenticated, a new object will be constructed and returned
 */
+ (DBUser*)currentUser;

/**
 * Attempts to log a User into the system with a given username and password
 */
- (void)loginWithUsername:(NSString*)username andPassword:(NSString*)password;

/**
 * Returns YES when the User is logged in
 */
- (BOOL)isLoggedIn;

/**
 * Logs the User out of the system
 */
- (void)logout;

@end

////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Notifications
 */
extern NSString* const DBUserDidLoginNotification; // Posted when the User logs in
extern NSString* const DBUserDidFailLoginNotification; // Posted when the User fails login. userInfo contains NSError with reason
extern NSString* const DBUserDidLogoutNotification; // Posted when the User logs out

/**
 * A protocol defining life-cycles events for a user logging in and out
 * of the application
 */
@protocol DBUserDelegate

/**
 * Sent to the delegate when the User has successfully authenticated
 */
- (void)userDidLogin:(DBUser*)user;

/**
 * Sent to the delegate when the User failed login for a specific reason
 */
- (void)user:(DBUser*)user didFailLoginWithError:(NSError*)error;

/**
 * Sent to the delegate when the User logged out of the system
 */
- (void)userDidLogout:(DBUser*)user;

@end
