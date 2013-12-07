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
#import "RKMIMETypeSerialization.h"
#import "RKNSJSONSerialization.h"

@interface RKMIMETypeSerialization ()
@property (nonatomic, strong) NSMutableArray *registrations;

+ (RKMIMETypeSerialization *)sharedSerialization;
- (void)addRegistrationsForKnownSerializations;
@end

@interface RKMIMETypeSerializationTest : RKTestCase
@end

@interface RKTestSerialization : NSObject <RKSerialization>
@end

@implementation RKTestSerialization

+ (id)objectFromData:(NSData *)data error:(NSError **)error
{
    return nil;
}

+ (NSData *)dataFromObject:(id)object error:(NSError **)error
{
    return nil;
}

@end

@implementation RKMIMETypeSerializationTest

- (void)setUp
{
    [RKMIMETypeSerialization sharedSerialization].registrations = [NSMutableArray array];
}

- (void)testShouldEnableRegistrationFromMIMETypeToParserClasses
{
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:RKMIMETypeJSON];
    Class parserClass = [RKMIMETypeSerialization serializationClassForMIMEType:RKMIMETypeJSON];
    assertThat(NSStringFromClass(parserClass), is(equalTo(@"RKNSJSONSerialization")));
}

- (void)testUnregisteringSerialization
{
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:RKMIMETypeJSON];
    Class parserClass = [RKMIMETypeSerialization serializationClassForMIMEType:RKMIMETypeJSON];
    assertThat(NSStringFromClass(parserClass), is(equalTo(@"RKNSJSONSerialization")));
    [RKMIMETypeSerialization unregisterClass:[RKNSJSONSerialization class]];
    parserClass = [RKMIMETypeSerialization serializationClassForMIMEType:RKMIMETypeJSON];
    assertThat(NSStringFromClass(parserClass), is(nilValue()));
}

- (void)testShouldAutoconfigureBasedOnReflection
{
    [[RKMIMETypeSerialization sharedSerialization] addRegistrationsForKnownSerializations];
    Class parserClass = [RKMIMETypeSerialization serializationClassForMIMEType:RKMIMETypeJSON];
    assertThat(NSStringFromClass(parserClass), is(equalTo(@"RKNSJSONSerialization")));
}

- (void)testRetrievalOfExactStringMatchForMIMEType
{
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:RKMIMETypeJSON];
    Class parserClass = [RKMIMETypeSerialization serializationClassForMIMEType:RKMIMETypeJSON];
    assertThat(NSStringFromClass(parserClass), is(equalTo(@"RKNSJSONSerialization")));
}

- (void)testRetrievalOfRegularExpressionMatchForMIMEType
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"application/xml\\+\\w+" options:0 error:&error];
    
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:regex];
    Class serializationClass = [RKMIMETypeSerialization serializationClassForMIMEType:@"application/xml+whatever"];
    assertThat(NSStringFromClass(serializationClass), is(equalTo(@"RKNSJSONSerialization")));
}

- (void)testRetrievalOfExactStringMatchIsFavoredOverRegularExpression
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"application/xml\\+\\w+" options:0 error:&error];
    
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:regex];
    [RKMIMETypeSerialization registerClass:[RKTestSerialization class] forMIMEType:@"application/xml+whatever"];

    // Exact match
    Class exactMatch = [RKMIMETypeSerialization serializationClassForMIMEType:@"application/xml+whatever"];
    assertThat(exactMatch, is(equalTo([RKTestSerialization class])));

    // Fallback to regex
    Class regexMatch = [RKMIMETypeSerialization serializationClassForMIMEType:@"application/xml+different"];
    assertThat(regexMatch, is(equalTo([RKNSJSONSerialization class])));
}

- (void)testSearchAcrossAllEntries
{
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"this/that"];
    [RKMIMETypeSerialization registerClass:[RKTestSerialization class] forMIMEType:@"application/xml+whatever"];
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"whatever"];
    
    Class exactMatch = [RKMIMETypeSerialization serializationClassForMIMEType:@"application/xml+whatever"];
    assertThat(exactMatch, is(equalTo([RKTestSerialization class])));
}

#pragma mark - RKMIMETypeInSet

- (void)testMIMETypeInSetWithStringMatch
{
    NSSet *acceptableMIMETypes = [NSSet setWithObjects:@"this/that", @"another/valid", @"woo", nil];
    assertThatBool(RKMIMETypeInSet(@"another/valid", acceptableMIMETypes), is(equalToBool(YES)));
    assertThatBool(RKMIMETypeInSet(@"this/that", acceptableMIMETypes), is(equalToBool(YES)));
    assertThatBool(RKMIMETypeInSet(@"woo", acceptableMIMETypes), is(equalToBool(YES)));
}

- (void)testMIMETypeInSetWithRegularExpressionMatch
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"application/xml\\+\\w+" options:0 error:nil];
    NSSet *acceptableMIMETypes = [NSSet setWithObjects:@"this/that", @"another/valid", regex, @"woo", nil];
    assertThatBool(RKMIMETypeInSet(@"application/xml+whatever", acceptableMIMETypes), is(equalToBool(YES)));
}

- (void)testMIMETypeInSetReturnsNoForMissingMIMEType
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"application/xml\\+\\w+" options:0 error:nil];
    NSSet *acceptableMIMETypes = [NSSet setWithObjects:@"this/that", @"another/valid", regex, @"woo", nil];
    assertThatBool(RKMIMETypeInSet(@"invalid", acceptableMIMETypes), is(equalToBool(NO)));
}

- (void)testShouldReturnNilAndSetErrorIfNoParserRegisteredWhenDeserializing
{
    NSError *error = nil;
    id object = [RKMIMETypeSerialization objectFromData:[NSData dataWithBytes:"foobar" length:6]
                                               MIMEType:@"application/json"
                                                  error:&error];
    assertThat(object, is(nilValue()));
    assertThat(error, isNot(nilValue()));
    assertThatInteger([error code], is(equalToInt(RKUnsupportedMIMETypeError)));
    assertThat([error domain], is(equalTo(RKErrorDomain)));
}

- (void)testDeserializationOfObjectInvokesRegisteredSerializationClass
{
    NSArray *parsedData = [NSArray array];
    NSError *error = nil;
    NSData *data = [@"foobar" dataUsingEncoding:NSUTF8StringEncoding];
    id mockSerializationClass = [OCMockObject mockForClass:[RKNSJSONSerialization class]];
    [[[[mockSerializationClass expect] classMethod] andReturn:parsedData] objectFromData:data error:[OCMArg setTo:error]];
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"application/bson"];
    id object = [RKMIMETypeSerialization objectFromData:data MIMEType:@"application/bson" error:&error];
    expect(object).to.equal(parsedData);
    expect(error).to.beNil();
    [mockSerializationClass verify];
    [mockSerializationClass stopMocking];
}

- (void)testShouldReturnNilAndSetErrorIfNoParserRegisteredWhenSerializing
{
    NSError *error = nil;
    NSObject *object = [NSObject new];
    NSData *data = [RKMIMETypeSerialization dataFromObject:object MIMEType:@"application/bson" error:&error];
    expect(data).to.beNil();
    expect(error).notTo.beNil();
    expect([error code]).to.equal(RKUnsupportedMIMETypeError);
    expect([error domain]).to.equal(RKErrorDomain);
}

- (void)testSerializationOfObjectInvokesRegisteredSerializationClass
{
    NSError *error = nil;
    NSData *data = [NSData data];
    NSObject *object = [NSObject new];
    id mockSerializationClass = [OCMockObject mockForClass:[RKNSJSONSerialization class]];
    [[[[mockSerializationClass expect] classMethod] andReturn:data] dataFromObject:object error:[OCMArg setTo:error]];
    [RKMIMETypeSerialization registerClass:[RKNSJSONSerialization class] forMIMEType:@"application/bson"];
    NSData *serializedData = [RKMIMETypeSerialization dataFromObject:object MIMEType:@"application/bson" error:&error];
    expect(serializedData).to.equal(data);
    expect(error).to.beNil();
    [mockSerializationClass verify];
    [mockSerializationClass stopMocking];
}

@end
