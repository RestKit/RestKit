//
//  RKParamsAttachmentTest.m
//  RestKit
//
//  Created by Blake Watters on 10/27/10.
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
#import "RKParamsAttachment.h"

@interface RKParamsAttachmentTest : RKTestCase {
}

@end


@implementation RKParamsAttachmentTest

- (void)testShouldRaiseAnExceptionWhenTheAttachedFileDoesNotExist
{
    NSException *exception = nil;
    @try {
        [[RKParamsAttachment alloc] initWithName:@"woot" file:@"/this/is/an/invalid/path"];
    }
    @catch (NSException *e) {
        exception = e;
    }
    assertThat(exception, isNot(nilValue()));
}

- (void)testShouldReturnAnMD5ForSimpleValues
{
    RKParamsAttachment *attachment = [[[RKParamsAttachment alloc] initWithName:@"foo" value:@"bar"] autorelease];
    assertThat([attachment MD5], is(equalTo(@"37b51d194a7513e45b56f6524f2d51f2")));
}

- (void)testShouldReturnAnMD5ForNSData
{
    RKParamsAttachment *attachment = [[[RKParamsAttachment alloc] initWithName:@"foo" data:[@"bar" dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
    assertThat([attachment MD5], is(equalTo(@"37b51d194a7513e45b56f6524f2d51f2")));
}

- (void)testShouldReturnAnMD5ForFiles
{
    NSString *filePath = [RKTestFixture pathForFixture:@"blake.png"];
    RKParamsAttachment *attachment = [[[RKParamsAttachment alloc] initWithName:@"foo" file:filePath] autorelease];
    assertThat([attachment MD5], is(equalTo(@"db6cb9d879b58e7e15a595632af345cd")));
}

@end
