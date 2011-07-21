//
//  RKParamsSpec.m
//  RestKit
//
//  Created by Blake Watters on 6/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKParams.h"
#import "RKRequest.h"

@interface RKParamsSpec : RKSpec

@end

@implementation RKParamsSpec

- (void)itShouldNotOverReleaseTheParams {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
    RKParams* params = [[RKParams alloc] initWithDictionary:dictionary];
    NSURL* URL = [NSURL URLWithString:[RKSpecGetBaseURL() stringByAppendingFormat:@"/echo_params"]];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.method = RKRequestMethodPOST;
    request.params = params;
    request.delegate = responseLoader;
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    [request release];
}

@end
