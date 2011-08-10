//
//  RKOAuthClientSpec.m
//  RestKit
//
//  Created by Rodrigo Garcia on 8/4/11.
//  Copyright 2011 RestKit. All rights reserved.
//


#import "RKSpecEnvironment.h"

@interface RKOAuthClientSpec : RKSpec

@end

@implementation RKOAuthClientSpec

- (void)itShouldGetAccessToken{
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKClientOAuth *client = RKSpecNewClientOAuth(loader);
    client.authorizationCode = @"1234";
    client.callbackURL = @"http://someURL.com";
    [client validateAuthorizationCode];
    [loader waitForResponse];
    assertThat([client getAccessToken], is(equalTo(@"581b50dca15a9d41eb280d5cbd52c7da4fb564621247848171508dd9d0dfa551a2efe9d06e110e62335abf13b6446a5c49e4bf6007cd90518fbbb0d1535b4dbc")));
}

- (void)itShouldGetProtectedResource{
    //TODO: Encapsulate this code in a correct manner
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKClientOAuth *client = RKSpecNewClientOAuth(loader);
    client.authorizationCode = @"1234";
    client.callbackURL = @"http://someURL.com";
    [client validateAuthorizationCode];

    
    RKSpecResponseLoader* resourceLoader = [RKSpecResponseLoader responseLoader];
    RKClient* requestClient = [RKClient clientWithBaseURL:[client authorizationURL]];
    requestClient.oAuth2AccessToken = [client getAccessToken];
    requestClient.forceOAuth2Use = true;
    RKRequest* request = [requestClient requestWithResourcePath:@"/me" delegate:resourceLoader];
    [request send];
    [resourceLoader waitForResponse];
    assertThatBool(loader.success, is(equalToBool(YES)));
}

@end
