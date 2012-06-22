//
//  RKParserRegistryTest.m
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
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
#import "RKParserRegistry.h"
#import "RKJSONParserJSONKit.h"
#import "RKXMLParserXMLReader.h"

@interface RKParserRegistryTest : RKTestCase {
}

@end

@implementation RKParserRegistryTest

- (void)testShouldEnableRegistrationFromMIMETypeToParserClasses
{
    RKParserRegistry *registry = [[RKParserRegistry new] autorelease];
    [registry setParserClass:[RKJSONParserJSONKit class] forMIMEType:RKMIMETypeJSON];
    Class parserClass = [registry parserClassForMIMEType:RKMIMETypeJSON];
    assertThat(NSStringFromClass(parserClass), is(equalTo(@"RKJSONParserJSONKit")));
}

- (void)testShouldInstantiateParserObjects
{
    RKParserRegistry *registry = [[RKParserRegistry new] autorelease];
    [registry setParserClass:[RKJSONParserJSONKit class] forMIMEType:RKMIMETypeJSON];
    id<RKParser> parser = [registry parserForMIMEType:RKMIMETypeJSON];
    assertThat(parser, is(instanceOf([RKJSONParserJSONKit class])));
}

- (void)testShouldAutoconfigureBasedOnReflection
{
    RKParserRegistry *registry = [[RKParserRegistry new] autorelease];
    [registry autoconfigure];
    id<RKParser> parser = [registry parserForMIMEType:RKMIMETypeJSON];
    assertThat(parser, is(instanceOf([RKJSONParserJSONKit class])));
    parser = [registry parserForMIMEType:RKMIMETypeXML];
    assertThat(parser, is(instanceOf([RKXMLParserXMLReader class])));
}

- (void)testRetrievalOfExactStringMatchForMIMEType
{
    RKParserRegistry *registry = [[RKParserRegistry new] autorelease];
    [registry setParserClass:[RKJSONParserJSONKit class] forMIMEType:RKMIMETypeJSON];
    id<RKParser> parser = [registry parserForMIMEType:RKMIMETypeJSON];
    assertThat(parser, is(instanceOf([RKJSONParserJSONKit class])));
}

- (void)testRetrievalOfRegularExpressionMatchForMIMEType
{
    RKParserRegistry *registry = [[RKParserRegistry new] autorelease];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"application/xml\\+\\w+" options:0 error:&error];
    [registry setParserClass:[RKJSONParserJSONKit class] forMIMETypeRegularExpression:regex];
    id<RKParser> parser = [registry parserForMIMEType:@"application/xml+whatever"];
    assertThat(parser, is(instanceOf([RKJSONParserJSONKit class])));
}

- (void)testRetrievalOfExactStringMatchIsFavoredOverRegularExpression
{
    RKParserRegistry *registry = [[RKParserRegistry new] autorelease];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"application/xml\\+\\w+" options:0 error:&error];
    [registry setParserClass:[RKJSONParserJSONKit class] forMIMETypeRegularExpression:regex];
    [registry setParserClass:[RKXMLParserXMLReader class] forMIMEType:@"application/xml+whatever"];

    // Exact match
    id<RKParser> exactParser = [registry parserForMIMEType:@"application/xml+whatever"];
    assertThat(exactParser, is(instanceOf([RKXMLParserXMLReader class])));

    // Fallback to regex
    id<RKParser> regexParser = [registry parserForMIMEType:@"application/xml+different"];
    assertThat(regexParser, is(instanceOf([RKJSONParserJSONKit class])));
}

@end
