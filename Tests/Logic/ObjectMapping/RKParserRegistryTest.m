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

- (void)testShouldReturnNilAndSetErrorIfNoParserRegisteredWhenParsing {
    NSError *error = nil;
    id object = [[RKParserRegistry new] parseData:[NSData data]
                                     withMIMEType:@"application/json"
                                         encoding:NSUTF8StringEncoding
                                            error:&error];
    assertThat(object, is(nilValue()));
    assertThat(error, isNot(nilValue()));
    assertThatInteger([error code], is(equalToInt(RKParserRegistryMissingParserError)));
    assertThat([error domain], is(equalTo(RKErrorDomain)));
}

- (void)testShouldPassDataToParser {
    NSArray *parsedData = [NSArray array];
    NSError *error = nil;
    NSData *data = [@"foobar" dataUsingEncoding:NSUTF8StringEncoding];
    id mockParser = [OCMockObject mockForProtocol:@protocol(RKParser)];
    [[[mockParser expect] andReturn:parsedData] objectFromData:data error:[OCMArg setTo:error]];
    RKParserRegistry *registry = [RKParserRegistry sharedRegistry];
    id mockRegistry = [OCMockObject partialMockForObject:registry];
    [[[mockRegistry stub] andReturn:mockParser] parserForMIMEType:@"application/bson"];
    id object = [registry parseData:data
                       withMIMEType:@"application/bson"
                           encoding:NSUTF8StringEncoding
                              error:&error];
    assertThat(object, is(parsedData));
    assertThat(error, is(nilValue()));
}

- (void)testShouldReturnNilAndSetErrorIfNoParserRegisteredWhenSerializing {
    NSError *error = nil;
    NSObject *object = [NSObject new];
    NSData *data = [[RKParserRegistry new] serializeObject:object
                                               forMIMEType:@"application/json"
                                                     error:&error];
    assertThat(data, is(nilValue()));
    assertThat(error, isNot(nilValue()));
    assertThatInteger([error code], is(equalToInt(RKParserRegistryMissingParserError)));
    assertThat([error domain], is(equalTo(RKErrorDomain)));
}

- (void)testShouldSerializeWithParser {
    NSError *error = nil;
    NSData *data = [NSData data];
    NSObject *object = [NSObject new];
    id mockParser = [OCMockObject mockForProtocol:@protocol(RKParser)];
    [[[mockParser expect] andReturn:data] dataFromObject:object error:[OCMArg setTo:error]];
    RKParserRegistry *registry = [RKParserRegistry sharedRegistry];
    id mockRegistry = [OCMockObject partialMockForObject:registry];
    [[[mockRegistry stub] andReturn:mockParser] parserForMIMEType:@"application/bson"];
    NSData *serializedData = [registry serializeObject:object forMIMEType:@"application/bson" error:&error];
    assertThat(serializedData, is(equalTo(data)));
    assertThat(error, is(nilValue()));
}

- (void)testShouldInvokeParseMethodWithDefaultEncoding {
    id mockRegistry = [OCMockObject partialMockForObject:[RKParserRegistry new]];
    NSArray *parsedData = [NSArray array];
    NSData *data = [NSData data];
    NSString *MIMEType = @"application/json";
    NSError *error = [NSError new];
    [[[mockRegistry expect] andReturn:parsedData] parseData:data
                                               withMIMEType:MIMEType
                                                   encoding:NSUTF8StringEncoding
                                                      error:[OCMArg setTo:error]];
    id retVal = [mockRegistry parseData:data withMIMEType:MIMEType error:&error];
    [mockRegistry verify];
    assertThat(retVal, is(equalTo(parsedData)));
}

- (void)testShouldEnableRegistrationFromMIMETypeToParserClasses {
    RKParserRegistry* registry = [[RKParserRegistry new] autorelease];
    [registry setParserClass:[RKJSONParserJSONKit class] forMIMEType:RKMIMETypeJSON];
    Class parserClass = [registry parserClassForMIMEType:RKMIMETypeJSON];
    assertThat(NSStringFromClass(parserClass), is(equalTo(@"RKJSONParserJSONKit")));
}

- (void)testShouldInstantiateParserObjects {
    RKParserRegistry* registry = [[RKParserRegistry new] autorelease];
    [registry setParserClass:[RKJSONParserJSONKit class] forMIMEType:RKMIMETypeJSON];
    id<RKParser> parser = [registry parserForMIMEType:RKMIMETypeJSON];
    assertThat(parser, is(instanceOf([RKJSONParserJSONKit class])));
}

- (void)testShouldAutoconfigureBasedOnReflection {
    RKParserRegistry* registry = [[RKParserRegistry new] autorelease];
    [registry autoconfigure];
    id<RKParser> parser = [registry parserForMIMEType:RKMIMETypeJSON];
    assertThat(parser, is(instanceOf([RKJSONParserJSONKit class])));
    parser = [registry parserForMIMEType:RKMIMETypeXML];
    assertThat(parser, is(instanceOf([RKXMLParserXMLReader class])));
}

- (void)testRetrievalOfExactStringMatchForMIMEType {
    RKParserRegistry* registry = [[RKParserRegistry new] autorelease];
    [registry setParserClass:[RKJSONParserJSONKit class] forMIMEType:RKMIMETypeJSON];
    id<RKParser> parser = [registry parserForMIMEType:RKMIMETypeJSON];
    assertThat(parser, is(instanceOf([RKJSONParserJSONKit class])));
}

- (void)testRetrievalOfRegularExpressionMatchForMIMEType {
    RKParserRegistry *registry = [[RKParserRegistry new] autorelease];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"application/xml\\+\\w+" options:0 error:&error];
    [registry setParserClass:[RKJSONParserJSONKit class] forMIMETypeRegularExpression:regex];
    id<RKParser> parser = [registry parserForMIMEType:@"application/xml+whatever"];
    assertThat(parser, is(instanceOf([RKJSONParserJSONKit class])));
}

- (void)testRetrievalOfExactStringMatchIsFavoredOverRegularExpression {
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

- (void)testShoulBeAbleToParseForRegisteredMIMEType {
    RKParserRegistry *registry = [RKParserRegistry new];
    id mockParser = [OCMockObject mockForProtocol:@protocol(RKParser)];
    [registry setParserClass:mockParser forMIMEType:@"application/foobar"];
    assertThatBool([registry canParseMIMEType:@"application/foobar"], is(equalToBool(YES)));
}

#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 1070 || __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000

- (void)testShoulBeAbleToParseForRegisteredMIMETypeRegularExpression {
    RKParserRegistry *registry = [RKParserRegistry new];
    id mockParser = [OCMockObject mockForProtocol:@protocol(RKParser)];
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:@"(text|application)\\/json"
                                                                                options:NSRegularExpressionSearch
                                                                                  error:NULL];
    [registry setParserClass:mockParser forMIMETypeRegularExpression:expression];
    assertThatBool([registry canParseMIMEType:@"text/json"], is(equalToBool(YES)));
}

#endif

- (void)testShoulNotBeAbleToParseForNotRegisteredMIMEType {
    RKParserRegistry *registry = [RKParserRegistry new];
    assertThatBool([registry canParseMIMEType:@"application/foobar"], is(equalToBool(NO)));
}

@end
