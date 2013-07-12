//
//  RKTwitterAppDelegate.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RKTwitterAppDelegate.h"
#import "RKTwitterViewController.h"
#import "RKTweet.h"
#import "RKTUser.h"

@implementation RKTwitterAppDelegate

@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    RKLogConfigureByName("RestKit/Network*", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);

    //let AFNetworking manage the activity indicator
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
  
    // Initialize HTTPClient
    NSURL *baseURL = [NSURL URLWithString:@"https://twitter.com"];
    AFHTTPClient* client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    
    // HACK: Set User-Agent to Mac OS X so that Twitter will let us access the Timeline
    [client setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]]];
    
    //we want to work with JSON-Data
    [client setDefaultHeader:@"Accept" value:RKMIMETypeJSON];
  
    // Initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
  
    // Setup our object mappings
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{
     @"id" : @"userID",
     @"screen_name" : @"screenName",
     @"name" : @"name"
     }];

    RKObjectMapping *statusMapping = [RKObjectMapping mappingForClass:[RKTweet class]];
    [statusMapping addAttributeMappingsFromDictionary:@{
     @"id" : @"statusID",
     @"created_at" : @"createdAt",
     @"text" : @"text",
     @"url" : @"urlString",
     @"in_reply_to_screen_name" : @"inReplyToScreenName",
     @"favorited" : @"isFavorited",
     }];
    RKRelationshipMapping* relationShipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"user"
                                                                                             toKeyPath:@"user"
                                                                                           withMapping:userMapping];
    [statusMapping addPropertyMapping:relationShipMapping];

    // Update date format so that we can parse Twitter dates properly
    // Wed Sep 29 15:31:08 +0000 2010
    [RKObjectMapping addDefaultDateFormatterForString:@"E MMM d HH:mm:ss Z y" inTimeZone:nil];

    // Register our mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"/status/user_timeline/:username"
                                                                                           keyPath:nil
                                                                                       statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];

    // Create Window and View Controllers
    RKTwitterViewController *viewController = [[RKTwitterViewController alloc] initWithNibName:nil bundle:nil];
    UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
