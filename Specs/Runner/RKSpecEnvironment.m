//
//  RKSpecEnvironment.m
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
#import "RKSpecEnvironment.h"
#import "RKParserRegistry.h"

NSString* RKSpecMIMETypeForFixture(NSString* fileName);

NSString* RKSpecGetBaseURL(void) {
    char* ipAddress = getenv("RESTKIT_IP_ADDRESS");
    if (NULL == ipAddress) {
        ipAddress = "127.0.0.1";
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

RKClient* RKSpecNewClient(void) {
    RKClient* client = [RKClient clientWithBaseURL:RKSpecGetBaseURL()];
    [RKClient setSharedClient:client];    
    [client release];
    client.requestQueue.suspended = NO;
    
    return client;
}

RKOAuthClient* RKSpecNewOAuthClient(RKSpecResponseLoader* loader){
    [loader setTimeout:10];
    RKOAuthClient* client = [RKOAuthClient clientWithClientID:@"appID" secret:@"appSecret" delegate:loader];
    client.authorizationURL = [NSString stringWithFormat:@"%@/oauth/authorize",RKSpecGetBaseURL()];
    return client;
}


RKObjectManager* RKSpecNewObjectManager(void) {    
    [RKObjectMapping setDefaultDateFormatters:nil];
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    [RKObjectManager setSharedManager:objectManager];
    [RKClient setSharedClient:objectManager.client];
    
    // Force reachability determination
    [objectManager.client.reachabilityObserver getFlags];
    
    return objectManager;
}

// TODO: Store initialization should not be coupled to object manager...
RKManagedObjectStore* RKSpecNewManagedObjectStore(void) {
    RKManagedObjectStore* store = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKSpecs.sqlite"];
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    objectManager.objectStore = store;
    [objectManager.objectStore deletePersistantStore];
    return store;
}

void RKSpecClearCacheDirectory(void) {
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

// Read a fixture from the app bundle
NSString* RKSpecReadFixture(NSString* fileName) {
    NSError* error = nil;
    NSBundle *bundle = [NSBundle bundleForClass:[RKSpec class]];
    NSString* filePath = [bundle pathForResource:fileName ofType:nil];
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

//- (void)failWithException:(NSException *) e {
//    printf("%s:%i: error: %s\n",
//           [[[e userInfo] objectForKey:SenTestFilenameKey] cString],
//           [[[e userInfo] objectForKey:SenTestLineNumberKey] intValue],
//           [[[e userInfo] objectForKey:SenTestDescriptionKey] cString]);
//    [e raise];
//}

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
