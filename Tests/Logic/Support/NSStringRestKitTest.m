//
//  NSStringRestKitTest.m
//  RestKit
//
//  Created by Greg Combs on 9/2/11.
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

#import "RKTestEnvironment.h"
#import "RKPathUtilities.h"
#import "RKObjectMapperTestModel.h"
#import "RKURLEncodedSerialization.h"

@interface NSStringRestKitTest : RKTestCase

@end

@implementation NSStringRestKitTest

- (void)testShouldInterpolateObjects
{
    RKObjectMapperTestModel *person = [[RKObjectMapperTestModel alloc] init];
    person.name = @"CuddleGuts";
    person.age  = [NSNumber numberWithInt:6];
    NSString *interpolatedPath = RKPathFromPatternWithObject(@"/people/:name/:age", person);
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/CuddleGuts/6";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
}

- (void)testReturningTheMIMETypeForAPathWithXMLExtension
{
    NSString *MIMEType = RKMIMETypeFromPathExtension(@"/path/to/file.xml");
    assertThat(MIMEType, is(equalTo(@"application/xml")));
}

- (void)testReturningTheMIMETypeForAPathWithJSONExtension
{
    NSString *MIMEType = RKMIMETypeFromPathExtension(@"/path/to/file.json");
    assertThat(MIMEType, is(equalTo(@"application/json")));
}

@end
