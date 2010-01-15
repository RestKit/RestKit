//
//  OTRestModelManagerSpec.m
//  OTRestFramework
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Objective 3. All rights reserved.
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
	// TODO: Set the accept header...
	
	_responseLoader	= [[OTRestSpecResponseLoader alloc] init];
}

- (void)itShouldLoadAHuman {
	NSLog(@"Model Manager: %@", _modelManager);
	NSLog(@"Response Loader: %@", _responseLoader);
	OTRestRequest* request = [_modelManager loadModel:@"/humans/1.xml" delegate:_responseLoader callback:@selector(loadResponse:)];
	NSLog(@"Request: %@", request);
	[_responseLoader waitForResponse];
	OTHuman* blake = (OTHuman*) _responseLoader.response;
	[expectThat(blake.name) should:be(@"Blake Watters")];
}

- (void)itShouldLoadAllHumans {
	OTRestRequest* request = [_modelManager loadModels:@"/humans.xml" delegate:_responseLoader callback:@selector(loadResponse:)];
	NSLog(@"Request: %@", request);
	[_responseLoader waitForResponse];
	NSArray* humans = (NSArray*) _responseLoader.response;
	[expectThat([humans count]) should:be(4)];
	[expectThat([[humans objectAtIndex:0] class]) should:be([OTHuman class])];
}

- (void)itShouldLoadHumansInPages {
}

- (void)itShouldHandleConnectionFailures {
}

@end
