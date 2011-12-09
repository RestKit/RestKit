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
    RKOAuthClientErrorInvalidGrant              = 3001,     /* An invalid authorization code was encountered */
    RKOAuthClientErrorUnauthorizedClient        = 3002,     /* The client is not authorized to perform the action */
    RKOAuthClientErrorInvalidClient             = 3003,     /* Client authentication failed (e.g. unknown client, no
                                                               client authentication included, or unsupported
                                                               authentication method). */
    RKOAuthClientErrorInvalidRequest            = 3004,     /* The request is missing a required parameter, includes an
                                                               unsupported parameter value, repeats a parameter,
                                                               includes multiple credentials, utilizes more than one
                                                               mechanism for authenticating the client, or is otherwise
                                                               malformed. */
    RKOAuthClientErrorUnsupportedGrantType      = 3005,     /* The authorization grant type is not supported by the authorization server. */
    RKOAuthClientErrorInvalidScope              = 3006,     /* The requested scope is invalid, unknown, malformed, or exceeds the scope 
                                                               granted by the resource owner. */
    RKOAuthClientErrorRequestFailure            = 3007,     /* An underlying RKRequest failed due to an error. The userInfo dictionary
                                                               will contain an NSUnderlyingErrorKey with the details of the failure */
    RKOAuthClientErrorUnknown                   = 0         /* Error was encountered and error_description unknown */
} RKOAuthClientErrorCode;

@protocol RKOAuthClientDelegate;

/**
 An OAuth client implementation used for OAuth 2 authorization code flow.
 
 See http://tools.ietf.org/html/draft-ietf-oauth-v2-22
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

// General properties of the client
@property(nonatomic,retain) NSString *authorizationCode;

// OAuth Client ID and Secret
@property(nonatomic,retain) NSString *clientID;
@property(nonatomic,retain) NSString *clientSecret;

// OAuth EndPoints
@property(nonatomic,retain) NSString *authorizationURL;
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
 * Other OAuth2 protocol exceptions for the authorization code flow
 */

/**
 Sent to the delegate when the OAuth client encounters any error
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
