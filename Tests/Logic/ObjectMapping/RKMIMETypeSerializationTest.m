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

@end
