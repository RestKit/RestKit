//
//  RKModelManagerSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "UISpec.h"
#import "dsl/UIExpectation.h"

#import "RKModelManager.h"
#import "RKSpecResponseLoader.h"
#import "RKHuman.h"


@interface RKModelManagerSpec : NSObject <UISpec> {
	RKModelManager* _modelManager;
	RKSpecResponseLoader* _responseLoader;
}

@end

@implementation RKModelManagerSpec

- (void)beforeAll {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://%s:3000", getenv("RKREST_IP_ADDRESS")];
	_modelManager = [RKModelManager managerWithBaseURL:localBaseURL];
	_modelManager.objectStore = [[RKManagedObjectStore alloc] initWithStoreFilename:@"RKSpecs.sqlite"];
	[_modelManager registerModel:[RKHuman class] forElementNamed:@"human"];
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
	RKModelManager* modelManager = [RKModelManager managerWithBaseURL:localBaseURL];
	[modelManager loadModel:@"/humans/1" delegate:_responseLoader callback:@selector(loadResponse:)];
	[_responseLoader waitForResponse];
	[expectThat(_responseLoader.success) should:be(NO)];
}

- (void)itShouldLoadAHuman {
	[_modelManager loadModel:@"/humans/1" delegate:_responseLoader callback:@selector(loadResponse:)];
	[_responseLoader waitForResponse];
	RKHuman* blake = (RKHuman*) _responseLoader.response;
	[expectThat(blake.name) should:be(@"Blake Watters")];
}

- (void)itShouldLoadAllHumans {
	[_modelManager loadModels:@"/humans" delegate:_responseLoader callback:@selector(loadResponse:)];
	[_responseLoader waitForResponse];
	NSArray* humans = (NSArray*) _responseLoader.response;
	[expectThat([humans count]) should:be(4)];
	[expectThat([[humans objectAtIndex:0] class]) should:be([RKHuman class])];
}

- (void)itShouldLoadHumansInPages {
}

@end
