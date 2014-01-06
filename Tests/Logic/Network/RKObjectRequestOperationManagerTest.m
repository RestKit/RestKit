//
//  RKObjectRequestOperationManagerTest.m
//  RestKit
//
//  Created by Blake Watters on 1/5/14.
//  Copyright (c) 2014 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKObjectRequestOperationManager.h"

@interface RKObjectRequestOperationManagerTest : SenTestCase
@end

@implementation RKObjectRequestOperationManagerTest

#pragma mark - managerWithBaseURL:

- (void)testInitializationOfUnderlyingHTTPOperationManager
{
    RKObjectRequestOperationManager *manager = [RKObjectRequestOperationManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    expect(manager.HTTPRequestOperationManager).notTo.beNil();
    expect(manager.HTTPRequestOperationManager.responseSerializer).to.beInstanceOf([AFJSONResponseSerializer class]);
    expect(manager.HTTPRequestOperationManager.requestSerializer).to.beInstanceOf([AFHTTPRequestSerializer class]);
}

- (void)testInitializationOfRequestSerializer
{
    RKObjectRequestOperationManager *manager = [RKObjectRequestOperationManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    expect(manager.requestSerializer).to.beInstanceOf([RKRequestSerializer class]);
}

- (void)testInitializationOfResponseSerializationManager
{
    RKObjectRequestOperationManager *manager = [RKObjectRequestOperationManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    expect(manager.responseSerializationManager).to.beInstanceOf([RKResponseSerializationManager class]);
}

@end
