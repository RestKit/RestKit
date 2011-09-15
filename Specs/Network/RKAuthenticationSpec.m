//
//  RKAuthenticationSpec.m
//  RestKit
//
//  Created by Blake Watters on 3/14/11.
//  Copyright 2011 Two Toasters
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

#import "RKSpecEnvironment.h"
#import "RKClient.h"
#import "RKNetwork.h"

static NSString* const RKAuthenticationSpecUsername = @"restkit";
static NSString* const RKAuthenticationSpecPassword = @"authentication";

@interface RKAuthenticationSpec : RKSpec {
    
}

@end

@implementation RKAuthenticationSpec

- (void)beforeAll {
    RKNetworkSetGlobalCredentialPersistence(NSURLCredentialPersistenceNone);
}
                                            
- (void)itShouldAccessUnprotectedResourcePaths {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKClient* client = RKSpecNewClient();
    [client get:@"/authentication/none" delegate:loader];
    [loader waitForResponse];
    [expectThat([loader.response isOK]) should:be(YES)];
}

- (void)itShouldAuthenticateViaHTTPAuthBasic {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKClient* client = RKSpecNewClient();
    client.username = RKAuthenticationSpecUsername;
    client.password = RKAuthenticationSpecPassword;
    [client get:@"/authentication/basic" delegate:loader];
    [loader waitForResponse];
    [expectThat([loader.response isOK]) should:be(YES)];
}

- (void)itShouldFailAuthenticationWithInvalidCredentialsForHTTPAuthBasic {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKClient* client = RKSpecNewClient();
    client.username = RKAuthenticationSpecUsername;
    client.password = @"INVALID";
    [client get:@"/authentication/basic" delegate:loader];
    [loader waitForResponse];
    [expectThat([loader.response isOK]) should:be(NO)]; 
    [expectThat([loader.response statusCode]) should:be(0)];
    [expectThat([loader.failureError code]) should:be(NSURLErrorUserCancelledAuthentication)];
}

- (void)itShouldAuthenticateViaHTTPAuthDigest {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKClient* client = RKSpecNewClient();
    client.username = RKAuthenticationSpecUsername;
    client.password = RKAuthenticationSpecPassword;
    [client get:@"/authentication/digest" delegate:loader];
    [loader waitForResponse];
    [expectThat([loader.response isOK]) should:be(YES)];
}

@end
