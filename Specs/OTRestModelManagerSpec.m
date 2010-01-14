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
#import "Human.h"


@interface OTRestModelManagerSpec : NSObject <UISpec> {
	OTRestModelManager* _modelManager;
	OTRestSpecResponseLoader* _responseLoader;
}

@end

@implementation OTRestModelManagerSpec

- (void)beforeAll {
	_modelManager = [OTRestModelManager managerWithBaseURL:@"http://10.4.5.213:3000"];
	_modelManager.objectStore = [[OTRestManagedObjectStore alloc] initWithStoreFilename:@"OTRest_Specs.sqlite"];
	[_modelManager registerModel:[Human class] forElementNamed:@"human"];
	// TODO: Set the accept header...
	
	_responseLoader	= [[OTRestSpecResponseLoader alloc] init];
}

- (void)itShouldLoadAHuman {
	NSLog(@"Model Manager: %@", _modelManager);
	NSLog(@"Response Loader: %@", _responseLoader);
	OTRestRequest* request = [_modelManager loadModel:@"/humans/1.xml" delegate:_responseLoader callback:@selector(loadResponse:)];
	NSLog(@"Request: %@", request);
	[_responseLoader waitForResponse];
	Human* blake = (Human*) _responseLoader.response;
	[expectThat(blake.name) should:be(@"Blake Watters")];
}

- (void)itShouldLoadAllHumans {
}

- (void)itShouldLoadHumansInPages {
}

- (void)itShouldHandleConnectionFailures {
}

@end
