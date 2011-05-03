//
//  RKObjectManagerSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObjectManager.h"
#import "RKManagedObjectStore.h"
#import "RKSpecResponseLoader.h"
#import "RKHuman.h"

@interface RKObjectManagerSpec : NSObject <UISpec> {
	RKObjectManager* _objectManager;
	RKSpecResponseLoader* _responseLoader;
}

@end

@implementation RKObjectManagerSpec

- (void)beforeAll {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://localhost:4567"]; //getenv("RESTKIT_IP_ADDRESS")
	_objectManager = [[RKObjectManager objectManagerWithBaseURL:localBaseURL] retain];
	_objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKSpecs.sqlite"];
    [RKObjectManager setSharedManager:_objectManager];
    [_objectManager.objectStore deletePersistantStore];
	[_objectManager registerClass:[RKHuman class] forElementNamed:@"human"];
    [_objectManager registerClass:[RKHuman class] forElementNamed:@"humans"];
	
	_responseLoader	= [[RKSpecResponseLoader alloc] init];
}

- (void)itShouldDefaultToAnXMLMappingFormat {	
	[expectThat(_objectManager.format) should:be(RKMappingFormatJSON)];
}

- (void)itShouldSetTheAcceptHeaderAppropriatelyForTheFormat {
	_objectManager.format = RKMappingFormatJSON;
	[expectThat([_objectManager.client.HTTPHeaders valueForKey:@"Accept"]) should:be(@"application/json")];
}

- (void)itShouldLoadAHuman {
	[_objectManager loadObjectsAtResourcePath:@"/JSON/humans/1.json" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	RKHuman* blake = (RKHuman*)[_responseLoader.objects objectAtIndex:0];
	NSLog(@"Blake: %@ (name = %@)", blake, blake.name);
	[expectThat(blake.name) should:be(@"Blake Watters")];
}

- (void)itShouldLoadAllHumans {
	[_objectManager loadObjectsAtResourcePath:@"/JSON/humans/all.json" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	NSArray* humans = (NSArray*) _responseLoader.objects;
	[expectThat([humans count]) should:be(2)];
	[expectThat([[humans objectAtIndex:0] class]) should:be([RKHuman class])];
}

- (void)itShouldHandleConnectionFailures {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://127.0.0.1:3001"];
	RKObjectManager* modelManager = [RKObjectManager objectManagerWithBaseURL:localBaseURL];
	[modelManager loadObjectsAtResourcePath:@"/JSON/humans/1" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	[expectThat(_responseLoader.success) should:be(NO)];
}

@end
