//
//  RKParserRegistrySpec.m
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKParserRegistry.h"
#import "RKJSONParserJSONKit.h"
#import "RKXMLParserLibXML.h"

@interface RKParserRegistrySpec : RKSpec {
}

@end

@implementation RKParserRegistrySpec

- (void)itShouldEnableRegistrationFromMIMETypeToParserClasses {
    RKParserRegistry* registry = [[RKParserRegistry new] autorelease];
    [registry setParserClass:[RKJSONParserJSONKit class] forMIMEType:RKMIMETypeJSON];
    Class parserClass = [registry parserClassForMIMEType:RKMIMETypeJSON];
    assertThat(NSStringFromClass(parserClass), is(equalTo(@"RKJSONParserJSONKit")));
}

- (void)itShouldInstantiateParserObjects {
    RKParserRegistry* registry = [[RKParserRegistry new] autorelease];
    [registry setParserClass:[RKJSONParserJSONKit class] forMIMEType:RKMIMETypeJSON];
    id<RKParser> parser = [registry parserForMIMEType:RKMIMETypeJSON];
    assertThat(parser, is(instanceOf([RKJSONParserJSONKit class])));
}

- (void)itShouldAutoconfigureBasedOnReflection {
    RKParserRegistry* registry = [[RKParserRegistry new] autorelease];
    [registry autoconfigure];
    id<RKParser> parser = [registry parserForMIMEType:RKMIMETypeJSON];
    assertThat(parser, is(instanceOf([RKJSONParserJSONKit class])));
    parser = [registry parserForMIMEType:RKMIMETypeXML];
    assertThat(parser, is(instanceOf([RKXMLParserLibXML class])));
}

@end
