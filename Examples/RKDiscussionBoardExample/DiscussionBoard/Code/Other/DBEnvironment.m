//
//  DBEnvironment.m
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBEnvironment.h"

// TODO: Add conditional compilation!
NSString* const DBRestKitBaseURL = @"http://localhost:3000";
//NSString* const kDBBaseURLString = @"http://discussionboard.heroku.com";
NSString* const kObjectCreatedUpdatedOrDestroyedNotificationName = @"kObjectCreatedUpdatedOrDestroyedNotificationName";

NSString* const kAccessTokenHeaderField = @"X-USER-ACCESS-TOKEN";