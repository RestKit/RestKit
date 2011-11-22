//
//  RKParserRegistrySpec.m
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
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
#import "RKParserRegistry.h"
#import "RKJSONParserJSONKit.h"
#import "RKXMLParserLibXML.h"

@interface RKParserRegistrySpec : RKSpec {
}

@end

@implementation RKParserRegistrySpec

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
    assertThat(parser, is(instanceOf([RKXMLParserLibXML class])));
}

@end
