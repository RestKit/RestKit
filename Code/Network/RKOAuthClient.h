//
//  RKOAuthClient.h
//  RestKit
//
//  Created by Rodrigo Garcia on 7/20/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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
 Defines error codes for OAuth client errors that are returned via a callback
 to RKOAuthClient's delegate
 */
typedef enum RKOAuthClientErrors {
    /**
     An invalid authorization code was encountered
     */
    RKOAuthClientErrorInvalidGrant              = 3001,
    /**
     The client is not authorized to perform the action
     */
    RKOAuthClientErrorUnauthorizedClient        = 3002,
    /**
     Client authentication failed (e.g. unknown client, no client
     authentication included, or unsupported authentication method).
     */
    RKOAuthClientErrorInvalidClient             = 3003,
    /**
     The request is missing a required parameter, includes an unsupported
     parameter value, repeats a parameter, includes multiple credentials,
     utilizes more than one mechanism for authenticating the client, or is
     otherwise malformed.
     */
    RKOAuthClientErrorInvalidRequest            = 3004,
    /**
     The authorization grant type is not supported by the authorization server.
     */
    RKOAuthClientErrorUnsupportedGrantType      = 3005,
    /**
     The requested scope is invalid, unknown, malformed, or exceeds the scope
     granted by the resource owner.
     */
    RKOAuthClientErrorInvalidScope              = 3006,
    /**
     An underlying RKRequest failed due to an error. The userInfo dictionary
    will contain an NSUnderlyingErrorKey with the details of the failure
     */
    RKOAuthClientErrorRequestFailure            = 3007,
    /**
     Error was encountered and error_description unknown
     */
    RKOAuthClientErrorUnknown                   = 0
} RKOAuthClientErrorCode;

@protocol RKOAuthClientDelegate;


/**
 An OAuth client implementation that conforms to RKRequestDelegate to handle the
 authentication involved with the OAuth 2 authorization code flow.

 RKOAuthClient sets up a pre-configured RKRequest and RKResponse handler to give
 easy access to retrieving an access token and handling errors through
 RKOAuthClientDelegate.

 **Example**:

    RKOAuthClient *oauthClient;
    oauthClient = [RKClientOAuth clientWithClientID:@"YOUR_CLIENT_ID"
                                             secret:@"YOUR_CLIENT_SECRET"
                                           delegate:yourDelegate];
    oauthClient.authorizationCode = @"AUTHORIZATION_CODE";
    oauthClient.authorizationURL = @"https://foursquare.com/oauth2/authenticate";
    oauthClient.callbackURL = @"https://example.com/callback";
    [oauthClient validateAuthorizationCode];

 From here, errors and the access token are returned through the
 implementation of RKOAuthClientDelegate specified.

 For more information on the OAuth 2 implementation, see
 http://tools.ietf.org/html/draft-ietf-oauth-v2-22

 @see RKOAuthClientDelegate
 */
@interface RKOAuthClient : NSObject

///-----------------------------------------------------------------------------
/// @name Creating an RKOAuthClient
///-----------------------------------------------------------------------------

/**
 Initialize a new RKOAuthClient with OAuth client credentials.

 @param clientID The ID of your application obtained from the OAuth provider.
 @param secret Confidential key obtained from the OAuth provider that is used to
 sign requests sent to the authentication server.
 @return An RKOAuthClient initialized with a client ID and secret key.
 */
- (id)initWithClientID:(NSString *)clientID secret:(NSString *)secret;

/**
 Creates and returns an RKOAuthClient initialized with OAuth client credentials.

 @param clientID The ID of your application obtained from the OAuth provider.
 @param secret Confidential key obtained from the OAuth provider that is used to
 sign requests sent to the authentication server.
 @return An RKOAuthClient initialized with a client ID and secret key.
 */
+ (RKOAuthClient *)clientWithClientID:(NSString *)clientID secret:(NSString *)secret;


///-----------------------------------------------------------------------------
/// @name General properties
///-----------------------------------------------------------------------------

/**
 A delegate that must conform to the RKOAuthClientDelegate protocol.

 The delegate will get callbacks such as successful access token acquisitions as
 well as any errors that are encountered.  Reference the RKOAuthClientDelegate
 for more information.

 @see RKOAuthClientDelegate.
 */
@property (nonatomic, assign) id<RKOAuthClientDelegate> delegate;


///-----------------------------------------------------------------------------
/// @name Client credentials
///-----------------------------------------------------------------------------

/**
 The ID of your application obtained from the OAuth provider
 */
@property (nonatomic, retain) NSString *clientID;

/**
 Confidential key obtained from the OAuth provider that is used to sign requests
 sent to the authentication server.
 */
@property (nonatomic, retain) NSString *clientSecret;


///-----------------------------------------------------------------------------
/// @name Endpoints
///-----------------------------------------------------------------------------

/**
 A string of the URL where the authorization server can be accessed
 */
@property (nonatomic, retain) NSString *authorizationURL;

/**
 A string of the URL where authorization attempts will be redirected to
 */
@property (nonatomic, retain) NSString *callbackURL;


///-----------------------------------------------------------------------------
/// @name Working with the authorization flow
///-----------------------------------------------------------------------------

/**
 The authorization code is used in conjunction with your client secret to obtain
 an access token.
 */
@property (nonatomic, retain) NSString *authorizationCode;

/**
 Returns the access token retrieved from the authentication server
 */
@property (nonatomic, readonly) NSString *accessToken;

/**
 Fire a request to the authentication server to validate the authorization code
 that has been set on the authorizationCode property.  All responses are handled
 by the delegate.

 @see RKOAuthClientDelegate
 */
- (void)validateAuthorizationCode;

@end


/**
 The delegate of an RKOAuthClient object must adopt the RKOAuthClientDelegate
 protocol.  The protocol defines all methods relating to obtaining an
 accessToken and handling any errors along the way.  It optionally provides
 callbacks for many different OAuth2 exceptions that may occur during the
 authorization code flow.
 */
@protocol RKOAuthClientDelegate <NSObject>
@required

///-----------------------------------------------------------------------------
/// @name Successful responses
///-----------------------------------------------------------------------------

/**
 Sent when a new access token has been acquired

 @param client A reference to the RKOAuthClient that triggered the callback
 @param token A string of the access token acquired from the authentication
 server.
 */
- (void)OAuthClient:(RKOAuthClient *)client didAcquireAccessToken:(NSString *)token;


///-----------------------------------------------------------------------------
/// @name Handling errors
///-----------------------------------------------------------------------------

/**
 Sent when an access token request has failed due an invalid authorization code

 @param client A reference to the RKOAuthClient that triggered the callback
 @param error An NSError object containing the RKOAuthClientError that triggered
 the callback
 */
- (void)OAuthClient:(RKOAuthClient *)client didFailWithInvalidGrantError:(NSError *)error;

@optional

/**
 Sent to the delegate when the OAuth client encounters any error.

 @param client A reference to the RKOAuthClient that triggered the callback
 @param error An NSError object containing the RKOAuthClientError that triggered
 the callback
 */
- (void)OAuthClient:(RKOAuthClient *)client didFailWithError:(NSError *)error;

/**
 Sent when the client isn't authorized to perform the requested action

 @param client A reference to the RKOAuthClient that triggered the callback
 @param error An NSError object containing the RKOAuthClientError that triggered
 the callback
 */
- (void)OAuthClient:(RKOAuthClient *)client didFailWithUnauthorizedClientError:(NSError *)error;

/**
 Sent when an error is encountered with the OAuth client such as an unknown
 client, there is no client authentication included, or an unsupported
 authentication method was used.

 @param client A reference to the RKOAuthClient that triggered the callback
 @param error An NSError object containing the RKOAuthClientError that triggered
 the callback
 */
- (void)OAuthClient:(RKOAuthClient *)client didFailWithInvalidClientError:(NSError *)error;

/**
 Sent when the request sent to the authentication server is invalid

 @param client A reference to the RKOAuthClient that triggered the callback
 @param error An NSError object containing the RKOAuthClientError that triggered
 the callback
 */
- (void)OAuthClient:(RKOAuthClient *)client didFailWithInvalidRequestError:(NSError *)error;

/**
 Sent when the grant type specified isn't supported by the authentication server

 @param client A reference to the RKOAuthClient that triggered the callback
 @param error An NSError object containing the RKOAuthClientError that triggered
 the callback
 */
- (void)OAuthClient:(RKOAuthClient *)client didFailWithUnsupportedGrantTypeError:(NSError *)error;

/**
 Sent when the requested scope is invalid, unknown, malformed, or exceeds the
 scope granted by the resource owner.

 @param client A reference to the RKOAuthClient that triggered the callback
 @param error An NSError object containing the RKOAuthClientError that triggered
 the callback
 */
- (void)OAuthClient:(RKOAuthClient *)client didFailWithInvalidScopeError:(NSError *)error;

/**
 Sent to the delegate when an authorization code flow request failed due to a
 loading error somewhere within the RKRequest call

 @param client A reference to the RKOAuthClient that triggered the callback
 @param request A reference to the RKRequest that failed
 @param error An NSError object containing the RKOAuthClientError that triggered
 the callback
 */
- (void)OAuthClient:(RKOAuthClient *)client didFailLoadingRequest:(RKRequest *)request withError:(NSError *)error;

@end
