//
//  RKObjectManagerSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObjectManager.h"
#import "RKSpecResponseLoader.h"
#import "RKHuman.h"

@interface RKObjectManagerSpec : NSObject <UISpec> {
	RKObjectManager* _modelManager;
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
	NSString* localBaseURL = [NSString stringWithFormat:@"http://%s:3000", "localhost"]; //getenv("RESTKIT_IP_ADDRESS")
	NSLog(@"Local Base URL: %@", localBaseURL);
	_modelManager = [[RKObjectManager objectManagerWithBaseURL:localBaseURL] retain];
	_modelManager.objectStore = [[RKManagedObjectStore alloc] initWithStoreFilename:@"RKSpecs.sqlite"];
	[_modelManager registerClass:[RKHuman class] forElementNamed:@"human"];
	
	_responseLoader	= [[RKSpecResponseLoader alloc] init];
}

- (void)itShouldDefaultToAnXMLMappingFormat {	
	[expectThat(_modelManager.format) should:be(RKMappingFormatJSON)];
}

- (void)itShouldSetTheAcceptHeaderAppropriatelyForTheFormat {
	// TODO: re-enable when we implement XML support.
//	_modelManager.format = RKMappingFormatXML;
//	[expectThat([_modelManager.client.HTTPHeaders valueForKey:@"Accept"]) should:be(@"application/xml")];
	_modelManager.format = RKMappingFormatJSON;
	[expectThat([_modelManager.client.HTTPHeaders valueForKey:@"Accept"]) should:be(@"application/json")];
}

- (void)itShouldHandleConnectionFailures {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://%s:3001", getenv("RESTKIT_IP_ADDRESS")];
	RKObjectManager* modelManager = [RKObjectManager objectManagerWithBaseURL:localBaseURL];
	[modelManager loadObjectsAtResourcePath:@"/humans/1" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	[expectThat(_responseLoader.success) should:be(NO)];
}

- (void)itShouldLoadAHuman {
	NSLog(@"Model manager baase url: %@", [_modelManager.client baseURL]);
	[_modelManager loadObjectsAtResourcePath:@"/humans/1" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	RKHuman* blake = (RKHuman*)[_responseLoader.response objectAtIndex:0];;
	NSLog(@"Blake: %@", blake);
	[expectThat(blake.name) should:be(@"Blake Watters")];
}

- (void)itShouldLoadAllHumans {
	[_modelManager loadObjectsAtResourcePath:@"/humans" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	NSArray* humans = (NSArray*) _responseLoader.response;
	[expectThat([humans count]) should:be(4)];
	[expectThat([[humans objectAtIndex:0] class]) should:be([RKHuman class])];
}

- (void)itShouldLoadHumansInPages {
}

@end
