//
//  RKOAuthClient.h
//  RestKit
//
//  Created by Rodrigo Garcia on 7/20/11.
//  Copyright 2011 RestKit. All rights reserved.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import "RKClient.h"
#import "RKRequest.h"

/**
 Defines error codes for OAuth client errors
 */
typedef enum RKOAuthClientErrors {
    RKOAuthClientErrorInvalidGrant              = 3001,     // An invalid authorization code was encountered
    RKOAuthClientErrorUnauthorizedClient        = 3002,     // The client is not authorized to perform the action
    RKOAuthClientErrorInvalidClient             = 3003,     // 
    RKOAuthClientErrorInvalidRequest            = 3004,     // 
    RKOAuthClientErrorUnsupportedGrantType      = 3005,     // 
    RKOAuthClientErrorInvalidScope              = 3006,     // 
    RKOAuthClientErrorRequestError              = 3007      // 
} RKOAuthClientErrorCode;

@protocol RKOAuthClientDelegate;

/**
 * An OAuth client implementation used for OAuth 2 abstract flow. Obtains an access_token 
 * from a valid authorization_code issued from the authorization server. 
 * RKOAuthClientDelegate defines the client's delegate methods needed to handle the lifecycle of this flow.
 * 
 * Basic Definitions
 * ------------------------
 * 
 *  In the context of OAuth2 there are two basic concepts:
 * 
 *  - Client
 *  - Resource
 *  
 *  A Client  basically is your iOS application which will consume _resources_ from the Resource Server, using an access_token issued by the _Authorization Server_. 
 * 
 *  The Client needs to be registered in the Authorization Server, which will create a _unique_ clientId and clientSecret per application. Normally the client's developer do this process using an administrative interface provided by the API.
 * 
 *  In the abstract flow, the user of your iOS application obtains an authorization_code from the Authorization Server in order to give access to his information to this application. Them using the RKOAuthClient you request an access_token identifying your iOS application (defined by the clientId and clientSecret) and the user (defined by the authorization_code). The callbackURL is a parameter which you set in the application register process and can be a generic value (ie http://restkit.org).
 *  
 *
 * @warning This client is based in the draft v21 of the OAuth2 protocol.
 */
@interface RKOAuthClient : NSObject <RKRequestDelegate> {
	NSString *_clientID;
    NSString *_clientSecret;
	NSString *_authorizationCode;
    NSString *_authorizationURL;
    NSString *_callbackURL;
    NSString *_accessToken;
    id<RKOAuthClientDelegate> _delegate;
}

// An authorization code issued by the authorization server
@property(nonatomic,retain) NSString *authorizationCode;

// OAuth2 Client ID and Secret
@property(nonatomic,retain) NSString *clientID;
@property(nonatomic,retain) NSString *clientSecret;

// OAuth2 Authorization EndPoint
@property(nonatomic,retain) NSString *authorizationURL;

// OAuth2 Client CallbackURL
@property(nonatomic,retain) NSString *callbackURL;

/**
 Returns the access token retrieved
 */
@property (nonatomic, readonly) NSString *accessToken;

// Client Delegate
@property (nonatomic,assign) id<RKOAuthClientDelegate> delegate;

- (id)initWithClientID:(NSString *)clientId 
                secret:(NSString *)secret
              delegate:(id<RKOAuthClientDelegate>)delegate;

- (void)validateAuthorizationCode;

/**
 * Returns a RKOAuthClient configured with the cliendId and clientSecret.
 *
 */

+ (RKOAuthClient *)clientWithClientID:(NSString *)clientId 
                               secret:(NSString *)secret 
                             delegate:(id<RKOAuthClientDelegate>)delegate;

@end

/**
 * Lifecycle events for RKClientOAuth
 */
@protocol RKOAuthClientDelegate <NSObject>
@required

/**
 * Sent when a new access token has being acquired
 */
- (void)OAuthClient:(RKOAuthClient *)client didAcquireAccessToken:(NSString *)token;

/**
 * Sent when an access token request has failed due an invalid authorization code
 */
- (void)OAuthClient:(RKOAuthClient *)client didFailWithInvalidGrantError:(NSError *)error;

@optional

/**
 * Other OAuth2 protocol exceptions for the authorization code flow, which are sent to the delegate when RKOAuthClient encounters any error in the abstract flow lifecycle.
 */
- (void)OAuthClient:(RKOAuthClient *)client didFailWithError:(NSError *)error;

- (void)OAuthClient:(RKOAuthClient *)client didFailWithUnauthorizedClientError:(NSError *)error;

- (void)OAuthClient:(RKOAuthClient *)client didFailWithInvalidClientError:(NSError *)error;

- (void)OAuthClient:(RKOAuthClient *)client didFailWithInvalidRequestError:(NSError *)error;

- (void)OAuthClient:(RKOAuthClient *)client didFailWithUnsupportedGrantTypeError:(NSError *)error;

- (void)OAuthClient:(RKOAuthClient *)client didFailWithInvalidScopeError:(NSError *)error;

/** 
 Sent to the delegate when an authorization code flow request failed loading due to an error
 */
- (void)OAuthClient:(RKOAuthClient *)client didFailLoadingRequest:(RKRequest *)request withError:(NSError *)error;

@end
