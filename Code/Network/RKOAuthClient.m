//
//  RKOAuthClient.m
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

#import "RKOAuthClient.h"
#import "RKErrors.h"

@interface RKOAuthClient () <RKRequestDelegate>
@end

@implementation RKOAuthClient

@synthesize clientID = _clientID;
@synthesize clientSecret = _clientSecret;
@synthesize authorizationCode = _authorizationCode;
@synthesize authorizationURL = _authorizationURL;
@synthesize callbackURL = _callbackURL;
@synthesize delegate = _delegate;
@synthesize accessToken = _accessToken;

+ (RKOAuthClient *)clientWithClientID:(NSString *)clientID secret:(NSString *)secret
{
    RKOAuthClient *client = [[[self alloc] initWithClientID:clientID secret:secret] autorelease];
    return client;
}

- (id)initWithClientID:(NSString *)clientID secret:(NSString *)secret
{
    self = [super init];
    if (self) {
        _clientID = [clientID copy];
        _clientSecret = [secret copy];
    }

    return self;
}

- (void)dealloc
{
    [_clientID release];
    [_clientSecret release];
    [_accessToken release];

    [super dealloc];
}

- (void)validateAuthorizationCode
{
    NSString *httpBody = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&code=%@&redirect_uri=%@&grant_type=authorization_code",
                          _clientID, _clientSecret, _authorizationCode, _callbackURL];
    NSURL *URL = [NSURL URLWithString:_authorizationURL];
    RKRequest *theRequest = [RKRequest requestWithURL:URL];
    theRequest.delegate = self;
    [theRequest setHTTPBodyString:httpBody];
    [theRequest setMethod:RKRequestMethodPOST];
    [theRequest send];
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    NSError *error = nil;
    NSString *errorResponse = nil;

    //Use the parsedBody answer in NSDictionary

    NSDictionary *oauthResponse = (NSDictionary *)[response parsedBody:&error];
    if ([oauthResponse isKindOfClass:[NSDictionary class]]) {

        //Check the if an access token comes in the response
        _accessToken = [[oauthResponse objectForKey:@"access_token"] copy];
        errorResponse = [oauthResponse objectForKey:@"error"];

        if (_accessToken) {
            // W00T We got an accessToken
            [self.delegate OAuthClient:self didAcquireAccessToken:_accessToken];

            return;
        } else if (errorResponse) {
            // Heads-up! There is an error in the response
            // The possible errors are defined in the OAuth2 Protocol

            RKOAuthClientErrorCode errorCode = RKOAuthClientErrorUnknown;
            NSString *errorDescription = [oauthResponse objectForKey:@"error_description"];

            if ([errorResponse isEqualToString:@"invalid_grant"]) {
                errorCode = RKOAuthClientErrorInvalidGrant;
            }
            else if ([errorResponse isEqualToString:@"unauthorized_client"]) {
                errorCode = RKOAuthClientErrorUnauthorizedClient;
            }
            else if ([errorResponse isEqualToString:@"invalid_client"]) {
                errorCode = RKOAuthClientErrorInvalidClient;
            }
            else if ([errorResponse isEqualToString:@"invalid_request"]) {
                errorCode = RKOAuthClientErrorInvalidRequest;
            }
            else if ([errorResponse isEqualToString:@"unsupported_grant_type"]) {
                errorCode = RKOAuthClientErrorUnsupportedGrantType;
            }
            else if ([errorResponse isEqualToString:@"invalid_scope"]) {
                errorCode = RKOAuthClientErrorInvalidScope;
            }

            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      errorDescription, NSLocalizedDescriptionKey, nil];
            NSError *error = [NSError errorWithDomain:RKErrorDomain code:errorCode userInfo:userInfo];


            // Inform the delegate of what happened
            if ([self.delegate respondsToSelector:@selector(OAuthClient:didFailWithError:)]) {
                [self.delegate OAuthClient:self didFailWithError:error];
            }

            // Invalid grant
            if (errorCode == RKOAuthClientErrorInvalidGrant && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithInvalidGrantError:)]) {
                [self.delegate OAuthClient:self didFailWithInvalidGrantError:error];
            }

            // Unauthorized client
            if (errorCode == RKOAuthClientErrorUnauthorizedClient && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithUnauthorizedClientError:)]) {
                [self.delegate OAuthClient:self didFailWithUnauthorizedClientError:error];
            }

            // Invalid client
            if (errorCode == RKOAuthClientErrorInvalidClient && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithInvalidClientError:)]) {
                [self.delegate OAuthClient:self didFailWithInvalidClientError:error];
            }

            // Invalid request
            if (errorCode == RKOAuthClientErrorInvalidRequest && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithInvalidRequestError:)]) {
                [self.delegate OAuthClient:self didFailWithInvalidRequestError:error];
            }

            // Unsupported grant type
            if (errorCode == RKOAuthClientErrorUnsupportedGrantType && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithUnsupportedGrantTypeError:)]) {
                [self.delegate OAuthClient:self didFailWithUnsupportedGrantTypeError:error];
            }

            // Invalid scope
            if (errorCode == RKOAuthClientErrorInvalidScope && [self.delegate respondsToSelector:@selector(OAuthClient:didFailWithInvalidScopeError:)]) {
                [self.delegate OAuthClient:self didFailWithInvalidScopeError:error];
            }
        }
    } else if (error) {
        if ([self.delegate respondsToSelector:@selector(OAuthClient:didFailWithError:)]) {
            [self.delegate OAuthClient:self didFailWithError:error];
        }
    } else {
        // TODO: Logging...
    }
}


- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              error, NSUnderlyingErrorKey, nil];
    NSError *clientError = [NSError errorWithDomain:RKErrorDomain code:RKOAuthClientErrorRequestFailure userInfo:userInfo];
    if ([self.delegate respondsToSelector:@selector(OAuthClient:didFailLoadingRequest:withError:)]) {
        [self.delegate OAuthClient:self didFailLoadingRequest:request withError:clientError];
    }

    if ([self.delegate respondsToSelector:@selector(OAuthClient:didFailWithError:)]) {
        [self.delegate OAuthClient:self didFailWithError:clientError];
    }
}

@end
