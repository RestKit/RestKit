//
//  DBEnvironment.m
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBEnvironment.h"

//NSString* const kDBBaseURLString = @"http://localhost:3000";
NSString* const kDBBaseURLString = @"http://discussionboard.heroku.com";

NSString* const kCurrentUserIDKey = @"currentUserKey";

NSString* const kUserLoggedInNotificationName = @"kUserLoggedInNotificationName";
NSString* const kLoginCanceledNotificationName = @"kLoginCanceledNotificationName";
NSString* const kUserLoggedOutNotificationName = @"kUserLoggedOutNotificationName";
NSString* const kObjectCreatedUpdatedOrDestroyedNotificationName = @"kObjectCreatedUpdatedOrDestroyedNotificationName";