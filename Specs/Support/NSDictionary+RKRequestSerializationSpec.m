//
//  NSDictionary+RKRequestSerializationSpec.m
//  RestKit
//
//  Created by Blake Watters on 2/24/10.
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
#import "NSDictionary+RKRequestSerialization.h"
#import "NSDictionary+RKAdditions.h"

@interface NSDictionary_RKRequestSerializationSpec : RKSpec {
}

@end

@implementation NSDictionary_RKRequestSerializationSpec

- (void)itShouldHaveKeysAndValuesDictionaryInitializer {
    NSDictionary* dictionary1 = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", @"value2", @"key2", nil];
    NSDictionary* dictionary2 = [NSDictionary dictionaryWithKeysAndObjects:@"key", @"value", @"key2", @"value2", nil];
    [expectThat(dictionary2) should:be(dictionary1)];
}

- (void)itShouldEncodeUnicodeStrings {
    NSString *unicode = [NSString stringWithFormat:@"%CNo ser ni%Co, ser b%Cfalo%C%C", 0x00A1, 0x00F1, 0x00FA, 0x2026, 0x0021];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:unicode forKey:@"utf8"];
    NSString *validUnicode = @"utf8=%C2%A1No%20ser%20ni%C3%B1o%2C%20ser%20b%C3%BAfalo%E2%80%A6%21";
    assertThat([dictionary URLEncodedString], is(equalTo(validUnicode)));
}

- (void)itShouldEncodeURLStrings {
    NSString *url = @"http://some.server.com/path/action?subject=\"That thing I sent\"&email=\"me@me.com\"";
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:url forKey:@"url"];
    NSString *validURL = @"url=http%3A%2F%2Fsome.server.com%2Fpath%2Faction%3Fsubject%3D%22That%20thing%20I%20sent%22%26email%3D%22me%40me.com%22";
    assertThat([dictionary URLEncodedString], is(equalTo(validURL)));
}

- (void)itShouldEncodeArrays {
    NSArray *array = [NSArray arrayWithObjects:@"item1", @"item2", nil];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:array forKey:@"anArray"];
    NSString *validArray = @"anArray[]=item1&anArray[]=item2";
    assertThat([dictionary URLEncodedString], is(equalTo(validArray)));
}

- (void)itShouldEncodeDictionaries {
    NSDictionary *subDictionary = [NSDictionary dictionaryWithObject:@"value1" forKey:@"key1"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:subDictionary forKey:@"aDictionary"];
    NSString *validDictionary = @"aDictionary[key1]=value1";
    assertThat([dictionary URLEncodedString], is(equalTo(validDictionary)));
}

- (void)itShouldEncodeRecursiveArrays {
    NSArray *recursiveArray3 = [NSArray arrayWithObjects:@"item1", @"item2", nil];
    NSArray *recursiveArray2 = [NSArray arrayWithObject:recursiveArray3];
    NSArray *recursiveArray1 = [NSArray arrayWithObject:recursiveArray2];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:recursiveArray1 forKey:@"recursiveArray"];
    NSString *validRecursion = @"recursiveArray[]=%28%0A%20%20%20%20%20%20%20%20%28%0A%20%20%20%20%20%20%20%20item1%2C%0A%20%20%20%20%20%20%20%20item2%0A%20%20%20%20%29%0A%29";
    assertThat([dictionary URLEncodedString], is(equalTo(validRecursion)));
}

@end
