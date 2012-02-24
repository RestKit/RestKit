//
//  RKTestEnvironment.h
//  RestKit
//
//  Created by Blake Watters on 1/15/10.
//  Copyright 2010 RestKit
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <OCMock/OCMock.h>
#import <OCMock/NSNotificationCenter+OCMAdditions.h>

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>
#import <SenTestingKit/SenTestingKit.h>

#import "RestKit.h"
#import "Testing.h"
#import "RKManagedObjectStore.h"

////////////////////////////////////////////////////////////////////////////
// OCMock - For some reason this macro is incorrect. Note the use of __typeof

#undef OCMOCK_VALUE
#define OCMOCK_VALUE(variable) [NSValue value:&variable withObjCType:@encode(__typeof(variable))]

// The Base URL for the Spec server. See Specs/Server/
RKURL* RKTestGetBaseURL(void);
NSString* RKTestGetBaseURLString(void);

// Helpers for returning new instances that clear global state
RKClient* RKTestNewClient(void);
RKObjectManager* RKTestNewObjectManager(void);
RKOAuthClient* RKTestNewOAuthClient(RKTestResponseLoader* loader);
void RKTestClearCacheDirectory(void);
void RKTestSpinRunLoop(void);
void RKTestSpinRunLoopWithDuration(NSTimeInterval timeInterval);

/* 
 Base class for RestKit test cases. Provides initialization of testing
 infrastructure.
 */
@interface RKTestCase : SenTestCase
@end

@interface SenTestCase (MethodSwizzling)
- (void)swizzleMethod:(SEL)aOriginalMethod
              inClass:(Class)aOriginalClass
           withMethod:(SEL)aNewMethod
            fromClass:(Class)aNewClass
         executeBlock:(void (^)(void))aBlock;
@end
