//
//  RKResourceManagerSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKResourceManager.h"
#import "RKSpecResponseLoader.h"
#import "RKHuman.h"

@interface RKResourceManagerSpec : NSObject <UISpec> {
	RKResourceManager* _modelManager;
	RKSpecResponseLoader* _responseLoader;
}

@end

@implementation RKResourceManagerSpec

- (void)beforeAll {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://%s:3000", getenv("RKREST_IP_ADDRESS")];
	_modelManager = [RKResourceManager managerWithBaseURL:localBaseURL];
	_modelManager.objectStore = [[RKManagedObjectStore alloc] initWithStoreFilename:@"RKSpecs.sqlite"];
	[_modelManager registerClass:[RKHuman class] forElementNamed:@"human"];
	_responseLoader	= [[RKSpecResponseLoader alloc] init];
}

- (void)itShouldDefaultToAnXMLMappingFormat {	
	[expectThat(_modelManager.format) should:be(RKMappingFormatXML)];
}

- (void)itShouldSetTheAcceptHeaderAppropriatelyForTheFormat {
	_modelManager.format = RKMappingFormatXML;
	[expectThat([_modelManager.client.HTTPHeaders valueForKey:@"Accept"]) should:be(@"application/xml")];
	_modelManager.format = RKMappingFormatJSON;
	[expectThat([_modelManager.client.HTTPHeaders valueForKey:@"Accept"]) should:be(@"application/json")];
}

- (void)itShouldHandleConnectionFailures {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://%s:3001", getenv("RKREST_IP_ADDRESS")];
	RKResourceManager* modelManager = [RKResourceManager managerWithBaseURL:localBaseURL];
	[modelManager loadResource:@"/humans/1" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	[expectThat(_responseLoader.success) should:be(NO)];
}

- (void)itShouldLoadAHuman {
	[_modelManager loadResource:@"/humans/1" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	RKHuman* blake = (RKHuman*) _responseLoader.response;
	[expectThat(blake.name) should:be(@"Blake Watters")];
}

- (void)itShouldLoadAllHumans {
	[_modelManager loadResource:@"/humans" delegate:_responseLoader];
	[_responseLoader waitForResponse];
	NSArray* humans = (NSArray*) _responseLoader.response;
	[expectThat([humans count]) should:be(4)];
	[expectThat([[humans objectAtIndex:0] class]) should:be([RKHuman class])];
}

- (void)itShouldLoadHumansInPages {
}

@end
