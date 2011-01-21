//
//  DBEnvironment.h
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

/**
 * The Base URL constant. This Base URL is used to initialize RestKit via RKClient
 * or RKObjectManager (which in turn initializes an instance of RKClient). The Base
 * URL is used to build full URL's by appending a resource path onto the end.
 *
 * By abstracting your Base URL into an externally defined constant and utilizing
 * conditional compilation, you can very quickly switch between server environments
 * and produce builds targetted at different backend systems.
 */
extern NSString* const DBRestKitBaseURL;

/**
 * Server Environments for conditional compilation
 */
#define DB_ENVIRONMENT_DEVELOPMENT 0
#define DB_ENVIRONMENT_STAGING 1
#define DB_ENVIRONMENT_PRODUCTION 2

// Use Production by default
#ifndef DB_ENVIRONMENT
#define DB_ENVIRONMENT DB_ENVIRONMENT_PRODUCTION
#endif
