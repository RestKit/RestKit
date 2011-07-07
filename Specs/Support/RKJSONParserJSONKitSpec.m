//
//  RKJSONParserJSONKitSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/6/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKJSONParserJSONKit.h"

@interface RKJSONParserJSONKitSpec : RKSpec

@end

@implementation RKJSONParserJSONKitSpec

- (void)itShouldParseEmptyResults {
    NSError* error = nil;
    RKJSONParserJSONKit* parser = [[RKJSONParserJSONKit new] autorelease];
    id parsingResult = [parser objectFromString:nil error:&error];
    assertThat(parsingResult, is(equalTo(nil)));
    assertThat(error, is(equalTo(nil)));
}

@end
