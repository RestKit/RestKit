//
//  RKSpecEnvironment.m
//  RestKit
//
//  Created by Blake Watters on 3/14/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKParserRegistry.h"

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
    
    RKSpecNewRequestQueue();
    RKSpecStubNetworkAvailability(YES);
    
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
    RKSpecStubNetworkAvailability(YES);
    
    // This allows the manager to determine state.
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    
    return objectManager;
}

// TODO: Store initialization should not be coupled to object manager...
RKManagedObjectStore* RKSpecNewManagedObjectStore() {
    RKManagedObjectStore* store = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKSpecs.sqlite"];
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    objectManager.objectStore = store;
    [objectManager.objectStore deletePersistantStore];
    return store;
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

NSString* RKSpecMIMETypeForFixture(NSString* fileName) {
    NSString* extension = [[fileName pathExtension] lowercaseString];
    if ([extension isEqualToString:@"xml"]) {
        return RKMIMETypeXML;
    } else if ([extension isEqualToString:@"json"]) {
        return RKMIMETypeJSON;
    } else {
        return nil;
    }
}

id RKSpecParseFixture(NSString* fileName) {
    NSError* error = nil;
    NSString* data = RKSpecReadFixture(fileName);
    NSString* MIMEType = RKSpecMIMETypeForFixture(fileName);
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:MIMEType];
    id object = [parser objectFromString:data error:&error];
    if (object == nil) {
        RKLogCritical(@"Failed to parse JSON fixture '%@'. Error: %@", fileName, [error localizedDescription]);
        return nil;
    }
    
    return object;
}

@implementation RKSpec

- (void)failWithException:(NSException *) e {
    printf("%s:%i: error: %s\n",
           [[[e userInfo] objectForKey:SenTestFilenameKey] cString],
           [[[e userInfo] objectForKey:SenTestLineNumberKey] intValue],
           [[[e userInfo] objectForKey:SenTestDescriptionKey] cString]);
    [e raise];
}

@end
