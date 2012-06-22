//
//  RKOAuthClientTest.m
//  RestKit
//
//  Created by Rodrigo Garcia on 8/4/11.
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

#import "RKTestEnvironment.h"
#import "RKPortCheck.h"

#define RKOAuthClientTestSkipWithoutMongoDB() \
    if (! [self isMongoRunning]) { \
        NSLog(@"!! Skipping OAuth Test: MongoDB not running"); \
        return; \
    }

@interface RKOAuthClientTest : RKTestCase

@end

@implementation RKOAuthClientTest

- (BOOL)isMongoRunning
{
    static RKPortCheck *portCheck = nil;
    if (! portCheck) {
        portCheck = [[RKPortCheck alloc] initWithHost:@"localhost" port:27017];
        [portCheck run];
    }

    return [portCheck isOpen];
}

- (void)testShouldGetAccessToken
{
    RKOAuthClientTestSkipWithoutMongoDB();

    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKOAuthClient *client = RKTestNewOAuthClient(loader);
    client.authorizationCode = @"4fa8182d7184797dd5000002";
    client.callbackURL = @"http://someURL.com";
    [client validateAuthorizationCode];
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(YES)));
}

- (void)testShouldNotGetAccessToken
{
    RKOAuthClientTestSkipWithoutMongoDB();

    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKOAuthClient *client = RKTestNewOAuthClient(loader);
    client.authorizationCode = @"someInvalidAuthorizationCode";
    client.callbackURL = @"http://someURL.com";
    [client validateAuthorizationCode];
    [loader waitForResponse];

    assertThatBool(loader.wasSuccessful, is(equalToBool(NO)));
}

- (void)testShouldGetProtectedResource
{
    RKOAuthClientTestSkipWithoutMongoDB();

    //TODO: Encapsulate this code in a correct manner
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKOAuthClient *client = RKTestNewOAuthClient(loader);
    client.authorizationCode = @"4fa8182d7184797dd5000002";
    client.callbackURL = @"http://someURL.com";
    [client validateAuthorizationCode];

    RKTestResponseLoader *resourceLoader = [RKTestResponseLoader responseLoader];
    RKClient *requestClient = [RKClient clientWithBaseURLString:[client authorizationURL]];
    requestClient.OAuth2AccessToken = client.accessToken;
    requestClient.authenticationType = RKRequestAuthenticationTypeOAuth2;
    RKRequest *request = [requestClient requestWithResourcePath:@"/oauth2/pregen/me"];
    request.delegate = resourceLoader;
    [request send];
    [resourceLoader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(YES)));
}

@end
