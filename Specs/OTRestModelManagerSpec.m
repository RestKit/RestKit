//
//  OTRestModelManagerSpec.m
//  OTRestFramework
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "UISpec.h"
#import "dsl/UIExpectation.h"

#import "OTRestModelManager.h"
#import "OTRestSpecResponseLoader.h"
#import "OTHuman.h"


@interface OTRestModelManagerSpec : NSObject <UISpec> {
	OTRestModelManager* _modelManager;
	OTRestSpecResponseLoader* _responseLoader;
}

@end

@implementation OTRestModelManagerSpec

- (void)beforeAll {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://%s:3000", getenv("OTREST_IP_ADDRESS")];
	_modelManager = [OTRestModelManager managerWithBaseURL:localBaseURL];
	_modelManager.objectStore = [[OTRestManagedObjectStore alloc] initWithStoreFilename:@"OTRest_Specs.sqlite"];
	[_modelManager registerModel:[OTHuman class] forElementNamed:@"human"];
	_responseLoader	= [[OTRestSpecResponseLoader alloc] init];
}

- (void)itShouldDefaultToAnXMLMappingFormat {	
	[expectThat(_modelManager.format) should:be(OTRestMappingFormatXML)];
}

- (void)itShouldSetTheAcceptHeaderAppropriatelyForTheFormat {
	_modelManager.format = OTRestMappingFormatXML;
	[expectThat([_modelManager.client.HTTPHeaders valueForKey:@"Accept"]) should:be(@"application/xml")];
	_modelManager.format = OTRestMappingFormatJSON;
	[expectThat([_modelManager.client.HTTPHeaders valueForKey:@"Accept"]) should:be(@"application/json")];
}

- (void)itShouldHandleConnectionFailures {
	NSString* localBaseURL = [NSString stringWithFormat:@"http://%s:3001", getenv("OTREST_IP_ADDRESS")];
	OTRestModelManager* modelManager = [OTRestModelManager managerWithBaseURL:localBaseURL];
	[modelManager loadModel:@"/humans/1" delegate:_responseLoader callback:@selector(loadResponse:)];
	[_responseLoader waitForResponse];
	[expectThat(_responseLoader.success) should:be(NO)];
}

- (void)itShouldLoadAHuman {
	[_modelManager loadModel:@"/humans/1" delegate:_responseLoader callback:@selector(loadResponse:)];
	[_responseLoader waitForResponse];
	OTHuman* blake = (OTHuman*) _responseLoader.response;
	[expectThat(blake.name) should:be(@"Blake Watters")];
}

- (void)itShouldLoadAllHumans {
	[_modelManager loadModels:@"/humans" delegate:_responseLoader callback:@selector(loadResponse:)];
	[_responseLoader waitForResponse];
	NSArray* humans = (NSArray*) _responseLoader.response;
	[expectThat([humans count]) should:be(4)];
	[expectThat([[humans objectAtIndex:0] class]) should:be([OTHuman class])];
}

- (void)itShouldLoadHumansInPages {
}

@end
