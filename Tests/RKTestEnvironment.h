//
//  RKTestEnvironment.h
//  RestKit
//
//  Created by Blake Watters on 1/15/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

#import <RestKit/RestKit.h>
#import <RestKit/Testing.h>
#import <RestKit/RKManagedObjectStore.h>

RKOAuthClient *RKTestNewOAuthClient(RKTestResponseLoader *loader);

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
