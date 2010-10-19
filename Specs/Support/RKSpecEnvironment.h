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
//#import <RestKit/RestKit.h>
//#import <RestKit/CoreData/CoreData.h>

////////////////////////////////////////////////////////////////////////////
// OCMock - For some reason this macro is incorrect. Note the use of __typeof

#undef OCMOCK_VALUE
#define OCMOCK_VALUE(variable) [NSValue value:&variable withObjCType:@encode(__typeof(variable))]
