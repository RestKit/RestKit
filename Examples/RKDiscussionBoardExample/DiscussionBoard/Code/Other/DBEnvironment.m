//
//  DBEnvironment.m
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBEnvironment.h"

// Base URL
#if DB_ENVIRONMENT == DB_ENVIRONMENT_DEVELOPMENT
	NSString* const DBRestKitBaseURL = @"http://localhost:3000";
#elif DB_ENVIRONMENT == DB_ENVIRONMENT_STAGING
	// TODO: Need a staging environment...
#elif DB_ENVIRONMENT == DB_ENVIRONMENT_PRODUCTION
	NSString* const DBRestKitBaseURL = @"http://discussionboard.heroku.com";
#endif
