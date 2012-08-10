//
//  NSDictionary+RKRequestSerializationTest.m
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
#import "NSDictionary+RKRequestSerialization.h"
#import "NSDictionary+RKAdditions.h"

@interface NSDictionary_RKRequestSerializationTest : RKTestCase {
}

@end

@implementation NSDictionary_RKRequestSerializationTest

- (void)testShouldHaveKeysAndValuesDictionaryInitializer
{
    NSDictionary *dictionary1 = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", @"value2", @"key2", nil];
    NSDictionary *dictionary2 = [NSDictionary dictionaryWithKeysAndObjects:@"key", @"value", @"key2", @"value2", nil];
    assertThat(dictionary2, is(equalTo(dictionary1)));
}

- (void)testShouldEncodeUnicodeStrings
{
    NSString *unicode = [NSString stringWithFormat:@"%CNo ser ni%Co, ser b%Cfalo%C%C", 0x00A1, 0x00F1, 0x00FA, 0x2026, 0x0021];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:unicode forKey:@"utf8"];
    NSString *validUnicode = @"utf8=%C2%A1No%20ser%20ni%C3%B1o%2C%20ser%20b%C3%BAfalo%E2%80%A6%21";
    assertThat([dictionary stringWithURLEncodedEntries], is(equalTo(validUnicode)));
}

- (void)testShouldEncodeURLStrings
{
    NSString *url = @"http://some.server.com/path/action?subject=\"That thing I sent\"&email=\"me@me.com\"";
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:url forKey:@"url"];
    NSString *validURL = @"url=http%3A%2F%2Fsome.server.com%2Fpath%2Faction%3Fsubject%3D%22That%20thing%20I%20sent%22%26email%3D%22me%40me.com%22";
    assertThat([dictionary stringWithURLEncodedEntries], is(equalTo(validURL)));
}

- (void)testShouldEncodeArrays
{
    NSArray *array = [NSArray arrayWithObjects:@"item1", @"item2", nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:array forKey:@"anArray"];
    NSString *validArray = @"anArray[]=item1&anArray[]=item2";
    assertThat([dictionary stringWithURLEncodedEntries], is(equalTo(validArray)));
}

- (void)testShouldEncodeDictionaries
{
    NSDictionary *subDictionary = [NSDictionary dictionaryWithObject:@"value1" forKey:@"key1"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:subDictionary forKey:@"aDictionary"];
    NSString *validDictionary = @"aDictionary[key1]=value1";
    assertThat([dictionary stringWithURLEncodedEntries], is(equalTo(validDictionary)));
}

- (void)testShouldEncodeArrayOfDictionaries
{
    NSDictionary *dictA = [NSDictionary dictionaryWithKeysAndObjects:@"a", @"x", @"b", @"y", nil];
    NSDictionary *dictB = [NSDictionary dictionaryWithKeysAndObjects:@"a", @"1", @"b", @"2", nil];

    NSArray *array = [NSArray arrayWithObjects:dictA, dictB, nil];
    NSDictionary *dictRoot = [NSDictionary dictionaryWithKeysAndObjects:@"root", array, nil];

    NSString *validString = @"root[][a]=x&root[][b]=y&root[][a]=1&root[][b]=2";
    assertThat([dictRoot stringWithURLEncodedEntries], is(equalTo(validString)));
}

- (void)testShouldEncodeRecursiveArrays
{
    NSArray *recursiveArray3 = [NSArray arrayWithObjects:@"item1", @"item2", nil];
    NSArray *recursiveArray2 = [NSArray arrayWithObject:recursiveArray3];
    NSArray *recursiveArray1 = [NSArray arrayWithObject:recursiveArray2];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:recursiveArray1 forKey:@"recursiveArray"];
    NSString *validRecursion = @"recursiveArray[]=%28%0A%20%20%20%20%20%20%20%20%28%0A%20%20%20%20%20%20%20%20item1%2C%0A%20%20%20%20%20%20%20%20item2%0A%20%20%20%20%29%0A%29";
    assertThat([dictionary stringWithURLEncodedEntries], is(equalTo(validRecursion)));
}

@end
