//
//  NSStringRestKitSpec.m
//  RestKit
//
//  Created by Greg Combs on 9/2/11.
//  Copyright 2011 RestKit
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
#import "NSString+RestKit.h"
#import "RKObjectMapperSpecModel.h"

@interface NSStringRestKitSpec : RKSpec

@end

@implementation NSStringRestKitSpec

- (void)testShouldAppendQueryParameters {
    NSString *resourcePath = @"/controller/objects/";
    NSDictionary *queryParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"ascend", @"sortOrder",
                                 @"name", @"groupBy",nil];
    NSString *resultingPath = [resourcePath appendQueryParams:queryParams];
    assertThat(resultingPath, isNot(equalTo(nil)));
    NSString *expectedPath1 = @"/controller/objects/?sortOrder=ascend&groupBy=name";
    NSString *expectedPath2 = @"/controller/objects/?groupBy=name&sortOrder=ascend";
    BOOL isValidPath = ( [resultingPath isEqualToString:expectedPath1] || 
                         [resultingPath isEqualToString:expectedPath2] );
    assertThatBool(isValidPath, is(equalToBool(YES)));
}

- (void)testShouldInterpolateObjects {
    RKObjectMapperSpecModel *person = [[[RKObjectMapperSpecModel alloc] init] autorelease];
    person.name = @"CuddleGuts";
    person.age  = [NSNumber numberWithInt:6];
    NSString *interpolatedPath = [@"/people/:name/:age" interpolateWithObject:person];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/CuddleGuts/6";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
}

- (void)testShouldInterpolateObjectsWithDeprecatedParentheses {
    RKObjectMapperSpecModel *person = [[[RKObjectMapperSpecModel alloc] init] autorelease];
    person.name = @"CuddleGuts";
    person.age  = [NSNumber numberWithInt:6];
    NSString *interpolatedPath = [@"/people/(name)/(age)" interpolateWithObject:person];
    assertThat(interpolatedPath, isNot(equalTo(nil)));
    NSString *expectedPath = @"/people/CuddleGuts/6";
    assertThat(interpolatedPath, is(equalTo(expectedPath)));
}

- (void)testShouldParseQueryParameters {
    NSString *resourcePath = @"/views/thing/?keyA=valA&keyB=valB";
    NSDictionary *queryParams = [resourcePath queryParametersUsingEncoding:NSASCIIStringEncoding];
    assertThat(queryParams, isNot(empty()));
    assertThat(queryParams, hasCountOf(2));
    assertThat(queryParams, hasEntries(@"keyA", @"valA", @"keyB", @"valB", nil));
}

- (void)testShouldReturnTheMIMETypeForAPath {
    NSString *MIMEType = [@"/path/to/file.xml" MIMETypeForPathExtension];
    assertThat(MIMEType, is(equalTo(@"application/xml")));
}

- (void)itShouldKnowIfTheReceiverContainsAnIPAddress {
    assertThatBool([@"127.0.0.1" isIPAddress], equalToBool(YES));
    assertThatBool([@"173.45.234.197" isIPAddress], equalToBool(YES));
    assertThatBool([@"google.com" isIPAddress], equalToBool(NO));
    assertThatBool([@"just some random text" isIPAddress], equalToBool(NO));
}

@end
