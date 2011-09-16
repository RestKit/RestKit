//
//  RKClientOAuth.h
//  RestKit
//
//  Created by Rodrigo Garcia on 7/20/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "RKClient.h"
#import "RKRequest.h"

@protocol RKOAuth2Delegate;

@interface RKClientOAuth : NSObject <RKRequestDelegate>{
	NSString* _clientID;
    NSString* _clientSecret;
	NSString* _authorizationCode;
    NSString* _authorizationURL;
    NSString* _callbackURL;
    NSString* _accessToken;
    id <RKOAuth2Delegate> _oauth2Delegate;
}

// General properties of the client
@property(nonatomic,retain) NSString* authorizationCode;

// OAuth Client ID and Secret
@property(nonatomic,retain) NSString* clientID;
@property(nonatomic,retain) NSString* clientSecret;

// OAuth EndPoints
@property(nonatomic,retain) NSString* authorizationURL;
@property(nonatomic,retain) NSString* callbackURL;

// OAuth accessToken getter
- (NSString *)getAccessToken;

// Client Delegate
@property(nonatomic,retain) id <RKOAuth2Delegate> oauth2Delegate;

- (id)initWithClientID:(NSString *)clientId 
                secret:(NSString *)secret
              delegate:(id <RKOAuth2Delegate>)delegate;

- (void)validateAuthorizationCode;

+ (RKClientOAuth *)clientWithClientID:(NSString *)clientId 
                               secret:(NSString *)secret 
                             delegate:(id <RKOAuth2Delegate>)delegate;

@end

/**
 * Lifecycle events for RKClientOAuth
 */
@protocol RKOAuth2Delegate
@required

/**
 * Sent when a new access token has being acquired
 */
- (void)accessTokenAcquired:(NSString *)token;

/**
 * Sent when an access token request has failed due an invalid authorization code
 */
- (void)errInvalidGrant:(NSString *)description;

@optional

/**
 * Other OAuth2 protocol exceptions for the authorization code flow
 */

- (void)errUnauthorizedClient:(NSString *)description;

- (void)errInvalidClient:(NSString *)description;

- (void)errInvalidRequest:(NSString *)description;

- (void)errUnsupportedGrantType:(NSString *)description;

- (void)errInvalidScope:(NSString *)description;

/** The access_token request has ended with an error.
 */

- (void)tokenRequestDidFailWithError:(NSString *)description;

@end