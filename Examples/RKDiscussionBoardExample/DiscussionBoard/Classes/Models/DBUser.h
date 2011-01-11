//
//  DBUser.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>

@interface DBUser : RKManagedObject {
	// Transient. Used for login & signup
	NSString* _password;
	NSString* _passwordConfirmation;
}

@property (nonatomic, retain) NSString* email;
@property (nonatomic, retain) NSString* login;
// Access Token will only be populated on a logged in user.
@property (nonatomic, retain) NSString* singleAccessToken;
@property (nonatomic, retain) NSNumber* userID;

@property (nonatomic, retain) NSString* password;
@property (nonatomic, retain) NSString* passwordConfirmation;

+ (DBUser*)currentUser;
+ (void)logout;

@end
