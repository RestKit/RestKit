//
//  RKClientOAuth.m
//  RestKit
//
//  Created by Rodrigo Garcia on 7/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKClientOAuth.h"

@implementation RKClientOAuth
@synthesize clientID = _clientID, clientSecret = _clientSecret, authorizationCode = _authorizationCode, authorizationURL = _authorizationURL, callbackURL = _callbackURL, oauth2Delegate = _oauth2Delegate;


- (id)initWithClientID:(NSString *)clientId 
                secret:(NSString *)secret 
              delegate:(id <RKOAuth2Delegate>)delegate
{
    self = [super init];
    if (self) {
        _clientID = [clientId copy];
        _clientSecret = [secret copy];
        _oauth2Delegate = delegate;
    }
    
    return self;
}

-(void)validateAuthorizationCode{
    NSString *httpBody = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&code=%@&redirect_uri=%@",_clientID,_clientSecret,_authorizationCode,_callbackURL];
    RKClient* requestClient = [RKClient clientWithBaseURL:_authorizationURL];
    RKRequest* theRequest = [requestClient requestWithResourcePath:@"" delegate:self];
    [theRequest setHTTPBodyString:httpBody];
    [theRequest setMethod:RKRequestMethodPOST];
    [theRequest send];
}

+ (RKClientOAuth *)clientWithClientID:(NSString *)clientId 
                               secret:(NSString *)secret 
                             delegate:(id <RKOAuth2Delegate>)delegate{
    RKClientOAuth* client = [[[self alloc] initWithClientID:clientId secret:secret delegate:delegate] autorelease];
    return client;
}


-(NSString *)getAccessToken{
    return _accessToken;
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response{
    NSError* error = nil;
    id json = [[JSONDecoder decoder] objectWithData:[response body] error:&error];
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSDictionary *tokens = (NSDictionary *) json;
        if ((_accessToken = [tokens objectForKey:@"access_token"])) {
            NSLog(@"A new access token has being acquired");
            [_oauth2Delegate accessTokenAcquired];
        }
    }

}


- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error{
    NSLog(@"An error has being detected in the access token request %@", [error debugDescription]);
    [_oauth2Delegate accessTokenAcquiredWithProblems];
}


@end
