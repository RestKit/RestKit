//
//  RKSpecEnvironment.h
//  RestKit
//
//  Created by Blake Watters on 1/15/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

//#import <OCMock/OCMock.h>
//
///**
// * Redefine the OCMOCK_VALUE macro
// *
// * For some reason typeof and __typeof__ have changed behavior. Partial mocks that return
// * primitive types were broken out of the box with OCMock
// */
//#undef OCMOCK_VALUE
//#define OCMOCK_VALUE(variable) [NSValue value:&variable withObjCType:@encode(__typeof__(variable))]
//
//#import "UISpec.h"
//#import "dsl/UIExpectation.h"

#import "UISpec.h"
#import "UIBug.h"
#import "UIQuery.h"
#import "UIExpectation.h"

#import <OCMockObject.h>
#import <OCMockRecorder.h>
#import <OCMConstraint.h>
#import <OCMArg.h>
#import <NSNotificationCenter+OCMAdditions.h>

////////////////////////////////////////////////////////////////////////////
// OCMock - For some reason this macro is incorrect. Note the use of __typeof

#undef OCMOCK_VALUE
#define OCMOCK_VALUE(variable) [NSValue value:&variable withObjCType:@encode(__typeof(variable))]
