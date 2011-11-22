//
//  RKParamsAttachmentSpec.m
//  RestKit
//
//  Created by Blake Watters on 10/27/10.
//  Copyright 2010 Two Toasters
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

#import "RKSpecEnvironment.h"
#import "RKParamsAttachment.h"

@interface RKParamsAttachmentSpec : RKSpec {
}

@end


@implementation RKParamsAttachmentSpec

- (void)testShouldRaiseAnExceptionWhenTheAttachedFileDoesNotExist {
	NSException* exception = nil;
	@try {
		[[RKParamsAttachment alloc] initWithName:@"woot" file:@"/this/is/an/invalid/path"];
	}
	@catch (NSException* e) {
		exception = e;
	}
	assertThat(exception, isNot(nilValue()));
}

- (void)testShouldReturnAnMD5ForSimpleValues {
    RKParamsAttachment *attachment = [[[RKParamsAttachment alloc] initWithName:@"foo" value:@"bar"] autorelease];
    assertThat([attachment MD5], is(equalTo(@"37b51d194a7513e45b56f6524f2d51f2")));
}

- (void)testShouldReturnAnMD5ForNSData {
    RKParamsAttachment *attachment = [[[RKParamsAttachment alloc] initWithName:@"foo" data:[@"bar" dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
    assertThat([attachment MD5], is(equalTo(@"37b51d194a7513e45b56f6524f2d51f2")));
}

- (void)testShouldReturnAnMD5ForFiles {
    NSBundle *testBundle = [NSBundle bundleWithIdentifier:@"org.restkit.unit-tests"];
    NSString *filePath = [testBundle pathForResource:@"blake" ofType:@"png"];
    RKParamsAttachment *attachment = [[[RKParamsAttachment alloc] initWithName:@"foo" file:filePath] autorelease];
    assertThat([attachment MD5], is(equalTo(@"db6cb9d879b58e7e15a595632af345cd")));
}

@end
