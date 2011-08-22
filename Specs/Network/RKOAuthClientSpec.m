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
    assertThatBool(loader.success, is(equalToBool(YES)));
}

- (void)itShouldNotGetAccessToken{
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKClientOAuth *client = RKSpecNewClientOAuth(loader);
    client.authorizationCode = @"someInvalidAuthorizationCode";
    client.callbackURL = @"http://someURL.com";
    [client validateAuthorizationCode];
    [loader waitForResponse];
    
    assertThatBool(loader.success, is(equalToBool(NO)));

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
