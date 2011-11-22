//
//  RKJSONParserJSONKitSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/6/11.
//  Copyright 2011 Two Toasters
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
#import "RKJSONParserJSONKit.h"

@interface RKJSONParserJSONKitSpec : RKSpec

@end

@implementation RKJSONParserJSONKitSpec

- (void)testShouldParseEmptyResults {
    NSError* error = nil;
    RKJSONParserJSONKit* parser = [[RKJSONParserJSONKit new] autorelease];
    id parsingResult = [parser objectFromString:nil error:&error];
    assertThat(parsingResult, is(equalTo(nil)));
    assertThat(error, is(equalTo(nil)));
}

@end
