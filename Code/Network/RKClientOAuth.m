//
//  RKClientOAuth.m
//  RestKit
//
//  Created by Rodrigo Garcia on 7/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKClientOAuth.h"
#import "JSONKit.h"

@implementation RKOAuthClient
@synthesize clientID = _clientID, clientSecret = _clientSecret, authorizationCode = _authorizationCode, authorizationURL = _authorizationURL, accessTokenURL = _accessTokenURL;


- (id)initWithClientID:(NSString *)clientId 
                secret:(NSString *)secret
{
    self = [super init];
    if (self) {
        _clientID = [clientId copy];
        _clientSecret = [secret copy];
    }
    
    return self;
}

-(void)validateAuthorizationCode{
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_accessTokenURL]] autorelease];
    NSString *httpBody = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&code=%@&redirect_uri=%@",_clientID,_clientSecret,_authorizationCode,@"http://discovery.excelsys.prod:5555/mobile/oauth/showcode"];
    NSData *postData = [ httpBody dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];    
    
    [request setHTTPBody:postData];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];
    
    NSError* error = nil;
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request  returningResponse:nil error:&error];
    id json = [[JSONDecoder decoder] objectWithData:responseData error:&error];
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSDictionary *tokens = (NSDictionary *) json;
        if ((_accessToken = [tokens objectForKey:@"access_token"])) {
            NSLog(@"A new access token has being acquired");
        }
    }
}

-(NSString *)getAccessToken{
    return _accessToken;
}


@end
