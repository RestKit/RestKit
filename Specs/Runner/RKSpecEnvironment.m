//
//  RKSpecEnvironment.m
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
#import "RKParserRegistry.h"

NSString* RKSpecMIMETypeForFixture(NSString* fileName);

NSString* RKSpecGetBaseURL(void) {
    char* ipAddress = getenv("RESTKIT_IP_ADDRESS");
    if (NULL == ipAddress) {
        ipAddress = "127.0.0.1";
    }
    
    return [NSString stringWithFormat:@"http://%s:4567", ipAddress];
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
    [RKObjectManager setDefaultMappingQueue:dispatch_queue_create("org.restkit.ObjectMapping", DISPATCH_QUEUE_SERIAL)];
    [RKObjectMapping setDefaultDateFormatters:nil];
    RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:RKSpecGetBaseURL()];
    [RKObjectManager setSharedManager:objectManager];
    [RKClient setSharedClient:objectManager.client];
    
    return objectManager;
}

// TODO: Store initialization should not be coupled to object manager...
RKManagedObjectStore* RKSpecNewManagedObjectStore(void) {
    RKManagedObjectStore* store = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKSpecs.sqlite"];
    [store deletePersistantStore];
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    objectManager.objectStore = store;
    return store;
}

void RKSpecClearCacheDirectory(void) {
    NSError* error = nil;
    NSString* cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
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

void RKSpecSpinRunLoopWithDuration(NSTimeInterval timeInterval) {
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

void RKSpecSpinRunLoop() {
    RKSpecSpinRunLoopWithDuration(0.1);
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
