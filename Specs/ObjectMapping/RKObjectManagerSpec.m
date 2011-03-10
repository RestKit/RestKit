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

/*
 * For these specs to run the rails app in Specs/restkitspecs_rails must be running.
 * cd Specs/restkitspecs_rails
 * rake db:create db:migrate
 * rake db:seed_fu
 * ./script/server
 */

@implementation RKObjectManagerSpec

- (void)beforeAll {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://%s:4567", "localhost"]; //getenv("RESTKIT_IP_ADDRESS")
	NSLog(@"Local Base URL: %@", localBaseURL);
	_objectManager = [[RKObjectManager objectManagerWithBaseURL:localBaseURL] retain];
	_objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKSpecs.sqlite"];
	[_objectManager registerClass:[RKHuman class] forElementNamed:@"human"];
	
	_responseLoader	= [[RKSpecResponseLoader alloc] init];
}

- (void)itShouldDefaultToAnXMLMappingFormat {	
	[expectThat(_objectManager.format) should:be(RKMappingFormatJSON)];
}

- (void)itShouldSetTheAcceptHeaderAppropriatelyForTheFormat {
	// TODO: re-enable when we implement XML support.
//	_objectManager.format = RKMappingFormatXML;
//	[expectThat([_objectManager.client.HTTPHeaders valueForKey:@"Accept"]) should:be(@"application/xml")];
	_objectManager.format = RKMappingFormatJSON;
	[expectThat([_objectManager.client.HTTPHeaders valueForKey:@"Accept"]) should:be(@"application/json")];
}

- (void)itShouldLoadAHuman {
	NSLog(@"Model manager baase url: %@", [_objectManager.client baseURL]);
	[_objectManager loadObjectsAtResourcePath:@"/humans/1" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	RKHuman* blake = (RKHuman*)[_responseLoader.response objectAtIndex:0];;
	NSLog(@"Blake: %@", blake);
	[expectThat(blake.name) should:be(@"Blake Watters")];
}

- (void)itShouldLoadAllHumans {
	[_objectManager loadObjectsAtResourcePath:@"/humans" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	NSArray* humans = (NSArray*) _responseLoader.response;
	[expectThat([humans count]) should:be(4)];
	[expectThat([[humans objectAtIndex:0] class]) should:be([RKHuman class])];
}

- (void)itShouldHandleConnectionFailures {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://127.0.0.1:3001"];
	RKObjectManager* modelManager = [RKObjectManager objectManagerWithBaseURL:localBaseURL];
	[modelManager loadObjectsAtResourcePath:@"/humans/1" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	[expectThat(_responseLoader.success) should:be(NO)];
}

@end
