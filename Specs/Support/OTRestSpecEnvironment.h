//
//  OTRestSpecEnvironment.h
//  OTRestFramework
//
//  Created by Blake Watters on 1/15/10.
//  Copyright 2010 Objective 3. All rights reserved.
//

#import <OCMock/OCMock.h>

/**
 * Redefine the OCMOCK_VALUE macro
 *
 * For some reason typeof and __typeof__ have changed behavior. Partial mocks that return
 * primitive types were broken out of the box with OCMock
 */
#undef OCMOCK_VALUE
#define OCMOCK_VALUE(variable) [NSValue value:&variable withObjCType:@encode(__typeof__(variable))]

#import "UISpec.h"
#import "dsl/UIExpectation.h"
