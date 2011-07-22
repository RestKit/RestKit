//
//  RKSpecEnvironment.h
//  RestKit
//
//  Created by Blake Watters on 1/15/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "UISpec.h"
#import "UIExpectation.h"

#import <OCMock/OCMock.h>
#import <OCMock/NSNotificationCenter+OCMAdditions.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <SenTestingKit/SenTestingKit.h>

#import "RestKit.h"
#import "RKSpecResponseLoader.h"
#import "RKManagedObjectStore.h"

////////////////////////////////////////////////////////////////////////////
// OCMock - For some reason this macro is incorrect. Note the use of __typeof

#undef OCMOCK_VALUE
#define OCMOCK_VALUE(variable) [NSValue value:&variable withObjCType:@encode(__typeof(variable))]

// The Base URL for the Spec server. See Specs/Server/
NSString* RKSpecGetBaseURL(void);

// Stub out the return value of the Shared Client instance's isNetworkAvailable method
void RKSpecStubNetworkAvailability(BOOL isNetworkAvailable);

// Helpers for returning new instances that clear global state
RKClient* RKSpecNewClient(void);
RKRequestQueue* RKSpecNewRequestQueue(void);
RKObjectManager* RKSpecNewObjectManager(void);
RKManagedObjectStore* RKSpecNewManagedObjectStore(void);
void RKSpecClearCacheDirectory(void);

// Read the contents of a fixture file from the app bundle
NSString* RKSpecReadFixture(NSString* fileName);
id RKSpecParseFixture(NSString* fileName);

// Base class for specs. Allows UISpec to run the specs and use of Hamcrest matchers...
@interface RKSpec : NSObject <UISpec>
@end
