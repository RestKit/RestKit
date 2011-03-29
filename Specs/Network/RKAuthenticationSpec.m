//
//  RKAuthenticationSpec.m
//  RestKit
//
//  Created by Blake Watters on 3/14/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKClient.h"
#import "RKNetwork.h"

static NSString* const RKAuthenticationSpecUsername = @"restkit";
static NSString* const RKAuthenticationSpecPassword = @"authentication";

@interface RKAuthenticationSpec : NSObject <UISpec> {
    
}

@end

@implementation RKAuthenticationSpec

- (void)beforeAll {
    RKNetworkSetGlobalCredentialPersistence(NSURLCredentialPersistenceNone);
}
                                            
- (void)itShouldAccessUnprotectedResourcePaths {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKClient* client = [RKClient clientWithBaseURL:RKSpecGetBaseURL()];
    [client get:@"/authentication/none" delegate:loader];
    [loader waitForResponse];
    [expectThat([loader.response isOK]) should:be(YES)];
}

- (void)itShouldAuthenticateViaHTTPAuthBasic {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKClient* client = [RKClient clientWithBaseURL:RKSpecGetBaseURL()];
    client.username = RKAuthenticationSpecUsername;
    client.password = RKAuthenticationSpecPassword;
    [client get:@"/authentication/basic" delegate:loader];
    [loader waitForResponse];
    [expectThat([loader.response isOK]) should:be(YES)];
}

- (void)itShouldFailAuthenticationWithInvalidCredentialsForHTTPAuthBasic {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKClient* client = [RKClient clientWithBaseURL:RKSpecGetBaseURL()];
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
    RKClient* client = [RKClient clientWithBaseURL:RKSpecGetBaseURL()];
    client.username = RKAuthenticationSpecUsername;
    client.password = RKAuthenticationSpecPassword;
    [client get:@"/authentication/digest" delegate:loader];
    [loader waitForResponse];
    [expectThat([loader.response isOK]) should:be(YES)];
}

@end
