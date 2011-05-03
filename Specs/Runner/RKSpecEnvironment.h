//
//  RKSpecEnvironment.h
//  RestKit
//
//  Created by Blake Watters on 1/15/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "UISpec.h"
#import "UIBug.h"
#import "UIQuery.h"
#import "UIExpectation.h"

#import <OCMock/OCMock.h>
#import <OCMock/NSNotificationCenter+OCMAdditions.h>

#import "RestKit.h"
#import "RKSpecResponseLoader.h"

////////////////////////////////////////////////////////////////////////////
// OCMock - For some reason this macro is incorrect. Note the use of __typeof

#undef OCMOCK_VALUE
#define OCMOCK_VALUE(variable) [NSValue value:&variable withObjCType:@encode(__typeof(variable))]

// The Base URL for the Spec server. See Specs/Server/
NSString* RKSpecGetBaseURL();

// Stub out the return value of the Shared Client instance's isNetworkAvailable method
void RKSpecStubNetworkAvailability(BOOL isNetworkAvailable);

// Helpers for returning new instances that clear global state
RKClient* RKSpecNewClient();
RKObjectManager* RKSpecNewObjectManager();
RKRequestQueue* RKSpecNewRequestQueue();

// Read the contents of a fixture file from the app bundle
NSString* RKSpecReadFixture(NSString* fileName);
id RKSpecParseFixtureJSON(NSString* fileName);