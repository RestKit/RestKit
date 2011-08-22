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
    NSString* errorResponse = nil;
    
    //Use the parsedBody answer in NSDictionary
    
    NSDictionary* oauthResponse = (NSDictionary *) [response parsedBody:&error];
    if ([oauthResponse isKindOfClass:[NSDictionary class]]) {
        
        //Check the if an access token comes in the response
        
        if ((_accessToken = [oauthResponse objectForKey:@"access_token"])) {
           
            // W00T We got an accessToken
            
            [_oauth2Delegate accessTokenAcquired:_accessToken];
            }
        
        //Heads-up! There is an error in the response
        //The possible errors are defined in the OAuth2 Protocol
        else if((errorResponse = [oauthResponse objectForKey:@"error"] )){
            
            if([errorResponse isEqualToString:@"invalid_grant"]){
                [_oauth2Delegate errInvalidGrant:[oauthResponse objectForKey:@"error_description"]];

            }
            else if([errorResponse isEqualToString:@"unauthorized_client"]){
                [_oauth2Delegate errUnauthorizedClient:[oauthResponse objectForKey:@"error_description"]];

            }
            else if([errorResponse isEqualToString:@"invalid_client"]){
                [_oauth2Delegate errInvalidClient:[oauthResponse objectForKey:@"error_description"]];
            }
            else if([errorResponse isEqualToString:@"invalid_request"]){
                [_oauth2Delegate errInvalidRequest:[oauthResponse objectForKey:@"error_description"]];
            }
            else if([errorResponse isEqualToString:@"unsupported_grant_type"]){
                [_oauth2Delegate errUnauthorizedClient:[oauthResponse objectForKey:@"error_description"]];
            }
            else if([errorResponse isEqualToString:@"invalid_scope"]){
                [_oauth2Delegate errInvalidScope:[oauthResponse objectForKey:@"error_description"]];
            }

        }
    }

}


- (void)request:(RKRequest*)request didFailLoadWithError:(NSError*)error{
    [_oauth2Delegate tokenRequestDidFailWithError:[error debugDescription]];
}


@end
