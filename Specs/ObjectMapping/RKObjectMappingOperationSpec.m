//
//  RKObjectMappingOperationSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h" 

@interface TestMappable : NSObject {
    NSURL* _url;
    NSString* _boolString;
}

@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSString* boolString;

@end

@implementation TestMappable

@synthesize url = _url;
@synthesize boolString = _boolString;

@end

@interface RKObjectMappingOperationSpec : RKSpec {
    
}

@end

@implementation RKObjectMappingOperationSpec

- (void)itShouldNotUpdateEqualURLProperties {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"url", nil];
    NSURL* url1 = [NSURL URLWithString:@"http://www.restkit.org"];
    NSURL* url2 = [NSURL URLWithString:@"http://www.restkit.org"];
    assertThatBool(url1 == url2, is(equalToBool(NO)));
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    [object setUrl:url1];
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:url2, @"url", nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object objectMapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThatBool(object.url == url1, is(equalToBool(YES)));
    [operation release];
}

- (void)itShouldSuccessfullyMapBoolsToStrings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"boolString", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
    id data = [parser objectFromString:@"{\"boolString\":true}" error:nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:data destinationObject:object objectMapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.boolString, is(equalTo(@"true")));
    [operation release];
}

@end
