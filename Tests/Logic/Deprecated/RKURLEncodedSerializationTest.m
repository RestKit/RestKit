//
//  RKURLEncodedSerializationTest.m
//  RestKit
//
//  Created by Blake Watters on 2/24/10.
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
#import "RKURLEncodedSerialization.h"

@interface RKURLEncodedSerializationTest : RKTestCase

@end

@implementation RKURLEncodedSerializationTest

- (void)testShouldEncodeUnicodeStrings
{
    NSString *unicode = [NSString stringWithFormat:@"%CNo ser ni%Co, ser b%Cfalo%C%C", (unichar)0x00A1, (unichar)0x00F1, (unichar)0x00FA, (unichar)0x2026, (unichar)0x0021];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:unicode forKey:@"utf8"];
    NSString *validUnicode = @"utf8=%C2%A1No%20ser%20ni%C3%B1o%2C%20ser%20b%C3%BAfalo%E2%80%A6%21";
    NSString *encodedString = RKURLEncodedStringFromDictionaryWithEncoding(dictionary, NSUTF8StringEncoding);
    expect(encodedString).to.equal(validUnicode);
}

- (void)testShouldEncodeURLStrings
{
    NSString *url = @"http://some.server.com/path/action?subject=\"That thing I sent\"&email=\"me@me.com\"";
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:url forKey:@"url"];
    NSString *expectedURL = @"url=http%3A%2F%2Fsome.server.com%2Fpath%2Faction%3Fsubject%3D%22That%20thing%20I%20sent%22%26email%3D%22me%40me.com%22";
    NSString *actualURL = RKURLEncodedStringFromDictionaryWithEncoding(dictionary, NSUTF8StringEncoding);
    expect(actualURL).to.equal(expectedURL);
}

- (void)testShouldEncodeArrays
{
    NSArray *array = [NSArray arrayWithObjects:@"item1", @"item2", nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:array forKey:@"anArray"];
    NSString *expected = @"anArray[]=item1&anArray[]=item2";
    NSString *actual = RKURLEncodedStringFromDictionaryWithEncoding(dictionary, NSUTF8StringEncoding);
    expect(actual).to.equal(expected);
}

- (void)testShouldEncodeDictionaries
{
    NSDictionary *subDictionary = [NSDictionary dictionaryWithObject:@"value1" forKey:@"key1"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:subDictionary forKey:@"aDictionary"];
    NSString *expected = @"aDictionary[key1]=value1";
    NSString *actual = RKURLEncodedStringFromDictionaryWithEncoding(dictionary, NSUTF8StringEncoding);
    expect(actual).to.equal(expected);
}

- (void)testShouldEncodeArrayOfDictionaries
{
    NSDictionary *dictA = @{@"a": @"x", @"b": @"y"};
    NSDictionary *dictB = @{@"a": @"1", @"b": @"2"};

    NSArray *array = [NSArray arrayWithObjects:dictA, dictB, nil];
    NSDictionary *dictRoot = @{@"root" : array};

    NSString *expected = @"root[][a]=x&root[][b]=y&root[][a]=1&root[][b]=2";
    NSString *actual = RKURLEncodedStringFromDictionaryWithEncoding(dictRoot, NSUTF8StringEncoding);
    expect(actual).to.equal(expected);
}

- (void)testShouldEncodeRecursiveArrays
{
    NSArray *recursiveArray3 = [NSArray arrayWithObjects:@"item1", @"item2", nil];
    NSArray *recursiveArray2 = [NSArray arrayWithObject:recursiveArray3];
    NSArray *recursiveArray1 = [NSArray arrayWithObject:recursiveArray2];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:recursiveArray1 forKey:@"recursiveArray"];
    NSString *expected = @"recursiveArray[][][]=item1&recursiveArray[][][]=item2";
    NSString *actual = RKURLEncodedStringFromDictionaryWithEncoding(dictionary, NSUTF8StringEncoding);
    expect(actual).to.equal(expected);
}

- (void)testShouldParseQueryParameters
{
    NSString *resourcePath = @"/views/thing/?keyA=valA&keyB=valB";
    NSDictionary *queryParameters = RKQueryParametersFromStringWithEncoding(resourcePath, NSUTF8StringEncoding);
    expect(queryParameters).notTo.beEmpty();
    expect(queryParameters).to.haveCountOf(2);
    NSDictionary *expected = @{@"keyA": @"valA", @"keyB": @"valB"};
    expect(queryParameters).to.equal(expected);
}

- (void)testDictionaryFromURLEncodedStringWithSimpleKeyValues
{
    NSString *query = @"this=that&keyA=valueB";
    NSDictionary *dictionary = RKDictionaryFromURLEncodedStringWithEncoding(query, NSUTF8StringEncoding);
    expect(@"foo").to.equal(@"foo");
    NSDictionary *expectedDictionary = @{ @"this": @"that", @"keyA": @"valueB" };
    expect(dictionary).to.equal(expectedDictionary);
}

- (void)testDictionaryFromURLEncodedStringWithArrayValues
{
    NSString *query = @"this=that&this=theOther";
    NSDictionary *dictionary = RKDictionaryFromURLEncodedStringWithEncoding(query, NSUTF8StringEncoding);
    expect(@"foo").to.equal(@"foo");
    NSDictionary *expectedDictionary = @{ @"this": @[ @"that", @"theOther" ] };
    expect(dictionary).to.equal(expectedDictionary);
}

- (void)testParsingComplexQueryStringIntoDictionary
{
    NSString *query = @"resource_uri=%2Fapi%2Fv1%2Fdevices%2F60%2F&id=60&uuid=8BF7D194-FE8D-46BD-8D07-83F5C73C50B9&pass_token=QazYDHaLeg&apns_token=&organizations%5B%5D=%2Fapi%2Fv1%2Forganizations%2F1%2F&organizations%5B%5D=%2Fapi%2Fv1%2Forganizations%2F2%2F";
    NSDictionary *dictionary = RKDictionaryFromURLEncodedStringWithEncoding(query, NSUTF8StringEncoding);
    NSDictionary *expectedDictionary = @{ @"resource_uri": @"/api/v1/devices/60/", @"id": @"60", @"uuid": @"8BF7D194-FE8D-46BD-8D07-83F5C73C50B9", @"apns_token": @"", @"organizations[]": @[ @"/api/v1/organizations/1/", @"/api/v1/organizations/2/" ], @"pass_token": @"QazYDHaLeg"};
    expect(dictionary).to.equal(expectedDictionary);
}

@end
