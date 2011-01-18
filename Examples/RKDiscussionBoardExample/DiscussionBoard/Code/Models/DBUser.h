//
//  DBUser.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>

@interface DBUser : RKManagedObject {
	// Transient. Used for login & sign-up
	NSString* _password;
	NSString* _passwordConfirmation;
}

/**
 * The e-mail address of the User
 */
@property (nonatomic, retain) NSString* email;

/**
 * The username of the User
 */
// TODO: Inconsistencies between username & login
@property (nonatomic, retain) NSString* login;

// Access Token will only be populated on a logged in user.
/**
 * An Access Token returned when a User is authenticated
 */
// TODO: Check design on this
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

/**
 * A globally available singleton reference to the current User
 */
+ (DBUser*)currentUser;

// TODO: Change to an instance method...
+ (void)logout;


@end
