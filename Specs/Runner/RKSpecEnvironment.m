//
//  RKSpecEnvironment.m
//  RestKit
//
//  Created by Blake Watters on 3/14/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKJSONParser.h"

NSString* RKSpecGetBaseURL() {
    char* ipAddress = getenv("RESTKIT_IP_ADDRESS");
    if (NULL == ipAddress) {
        ipAddress = "localhost";
    }
    
    return [NSString stringWithFormat:@"http://%s:4567", ipAddress];
}

void RKSpecStubNetworkAvailability(BOOL isNetworkAvailable) {
    RKClient* client = [RKClient sharedClient];
    if (client) {
        id mockClient = [OCMockObject partialMockForObject:client];
        [[[mockClient stub] andReturnValue:OCMOCK_VALUE(isNetworkAvailable)] isNetworkAvailable];
    }
}

RKClient* RKSpecNewClient() {
    RKClient* client = [RKClient clientWithBaseURL:RKSpecGetBaseURL()];
    [RKClient setSharedClient:client];
    [client release];
    
    return client;
}

RKRequestQueue* RKSpecNewRequestQueue() {
    RKRequestQueue* requestQueue = [RKRequestQueue new];
    requestQueue.suspended = NO;
    [RKRequestQueue setSharedQueue:requestQueue];
    [requestQueue release];
    
    return requestQueue;
}

RKObjectManager* RKSpecNewObjectManager() {
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    [RKObjectManager setSharedManager:objectManager];
    [RKClient setSharedClient:objectManager.client];
    RKSpecNewRequestQueue();
    
    return objectManager;
}

// Read a fixture from the app bundle
NSString* RKSpecReadFixture(NSString* fileName) {
    NSError* error = nil;
    NSString* filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
	NSString* fixtureData = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (fixtureData == nil && error) {
        [NSException raise:nil format:@"Failed to read contents of fixture '%@'. Did you add it to the app bundle? Error: %@", fileName, [error localizedDescription]];
    }
	return fixtureData;
}

id RKSpecParseFixtureJSON(NSString* fileName) {
    NSString* JSON = RKSpecReadFixture(fileName);
    RKJSONParser* parser = [RKJSONParser new];    
    id result = [parser objectFromString:JSON];
    [parser release];
    return result;
}
