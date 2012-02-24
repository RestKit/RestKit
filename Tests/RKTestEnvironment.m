//
//  RKTestEnvironment.m
//  RestKit
//
//  Created by Blake Watters on 3/14/11.
//  Copyright 2011 RestKit
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

#include <objc/runtime.h>
#import "RKTestEnvironment.h"
#import "RKParserRegistry.h"

NSString* RKTestGetBaseURLString(void) {
    char* ipAddress = getenv("RESTKIT_IP_ADDRESS");
    if (NULL == ipAddress) {
        ipAddress = "127.0.0.1";
    }

    return [NSString stringWithFormat:@"http://%s:4567", ipAddress];
}

RKURL* RKTestGetBaseURL(void) {
    return [RKURL URLWithString:RKTestGetBaseURLString()];
}

RKClient* RKTestNewClient(void) {
    RKClient* client = [RKClient clientWithBaseURL:RKTestGetBaseURL()];
    [RKClient setSharedClient:client];
    [client release];
    client.requestQueue.suspended = NO;

    return client;
}

RKOAuthClient* RKTestNewOAuthClient(RKTestResponseLoader* loader){
    [loader setTimeout:10];
    RKOAuthClient* client = [RKOAuthClient clientWithClientID:@"appID" secret:@"appSecret"];
    client.delegate = loader;
    client.authorizationURL = [NSString stringWithFormat:@"%@/oauth/authorize", RKTestGetBaseURLString()];
    return client;
}

RKObjectManager* RKTestNewObjectManager(void) {
    [RKObjectManager setDefaultMappingQueue:dispatch_queue_create("org.restkit.ObjectMapping", DISPATCH_QUEUE_SERIAL)];
    [RKObjectMapping setDefaultDateFormatters:nil];
    RKObjectManager* objectManager = [RKObjectManager managerWithBaseURL:RKTestGetBaseURL()];
    [RKObjectManager setSharedManager:objectManager];
    [RKClient setSharedClient:objectManager.client];

    // Force reachability determination
    [objectManager.client.reachabilityObserver getFlags];

    return objectManager;
}

void RKTestClearCacheDirectory(void) {
    NSError* error = nil;
    NSString* cachePath = [RKDirectory cachesDirectory];
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:cachePath error:&error];
    if (success) {
        RKLogInfo(@"Cleared cache directory...");
        success = [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            RKLogError(@"Failed creation of cache path '%@': %@", cachePath, [error localizedDescription]);
        }
    } else {
        RKLogError(@"Failed to clear cache path '%@': %@", cachePath, [error localizedDescription]);
    }
}

void RKTestSpinRunLoopWithDuration(NSTimeInterval timeInterval) {
    BOOL waiting = YES;
	NSDate* startDate = [NSDate date];

	while (waiting) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		if ([[NSDate date] timeIntervalSinceDate:startDate] > timeInterval) {
			waiting = NO;
		}
        usleep(100);
	}
}

void RKTestSpinRunLoop() {
    RKTestSpinRunLoopWithDuration(0.1);
}

@implementation RKTestCase

- (void) invokeTest {
    // Ensure the fixture bundle is configured
    if (! [RKTestFixture fixtureBundle]) {
        NSBundle *fixtureBundle = [NSBundle bundleWithIdentifier:@"org.restkit.unit-tests"];
        [RKTestFixture setFixtureBundle:fixtureBundle];
    }

    [super invokeTest];
}

@end

@implementation SenTestCase (MethodSwizzling)
- (void)swizzleMethod:(SEL)aOriginalMethod
              inClass:(Class)aOriginalClass
           withMethod:(SEL)aNewMethod
            fromClass:(Class)aNewClass
         executeBlock:(void (^)(void))aBlock {
    Method originalMethod = class_getClassMethod(aOriginalClass, aOriginalMethod);
    Method mockMethod = class_getInstanceMethod(aNewClass, aNewMethod);
    method_exchangeImplementations(originalMethod, mockMethod);
    aBlock();
    method_exchangeImplementations(mockMethod, originalMethod);
}
@end
