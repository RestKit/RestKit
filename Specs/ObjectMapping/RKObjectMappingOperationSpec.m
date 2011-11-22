//
//  RKObjectMappingOperationSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
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
#import "RKObjectMapperError.h"
#import "RKMappableObject.h"
#import "RKMappableAssociation.h"

@interface TestMappable : NSObject {
    NSURL *_url;
    NSString *_boolString;
    NSDate *_date;
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *boolString;
@property (nonatomic, retain) NSNumber *boolNumber;
@property (nonatomic, retain) NSDate *date;

@end

@implementation TestMappable

@synthesize url = _url;
@synthesize boolString = _boolString;
@synthesize boolNumber = _boolNumber;
@synthesize date = _date;

- (BOOL)validateBoolString:(id *)ioValue error:(NSError **)outError {
    if ([(NSObject *)*ioValue isKindOfClass:[NSString class]] && [(NSString *)*ioValue isEqualToString:@"FAIL"]) {
        *outError = [NSError errorWithDomain:RKRestKitErrorDomain code:RKObjectMapperErrorUnmappableContent userInfo:nil];
        return NO;
    } else if ([(NSObject *)*ioValue isKindOfClass:[NSString class]] && [(NSString *)*ioValue isEqualToString:@"REJECT"]) {
        return NO;
    }
    
    return YES;
}

@end

@interface RKObjectMappingOperationSpec : RKSpec {
    
}

@end

@implementation RKObjectMappingOperationSpec

- (void)testShouldNotUpdateEqualURLProperties {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"url", nil];
    NSURL* url1 = [NSURL URLWithString:@"http://www.restkit.org"];
    NSURL* url2 = [NSURL URLWithString:@"http://www.restkit.org"];
    assertThatBool(url1 == url2, is(equalToBool(NO)));
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    [object setUrl:url1];
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:url2, @"url", nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThatBool(object.url == url1, is(equalToBool(YES)));
    [operation release];
}

- (void)testShouldSuccessfullyMapBoolsToStrings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"boolString", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
    id data = [parser objectFromString:@"{\"boolString\":true}" error:nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:data destinationObject:object mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.boolString, is(equalTo(@"true")));
    [operation release];
}

- (void)testShouldSuccessfullyMapTrueBoolsToNSNumbers {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"boolNumber", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
    id data = [parser objectFromString:@"{\"boolNumber\":true}" error:nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:data destinationObject:object mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThatInt([object.boolNumber intValue], is(equalToInt(1)));
    [operation release];
}

- (void)testShouldSuccessfullyMapFalseBoolsToNSNumbers {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"boolNumber", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
    id data = [parser objectFromString:@"{\"boolNumber\":false}" error:nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:data destinationObject:object mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThatInt([object.boolNumber intValue], is(equalToInt(0)));
    [operation release];
}

- (void)testShouldSuccessfullyMapNumbersToStrings {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapKeyPath:@"number" toAttribute:@"boolString"];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
    id data = [parser objectFromString:@"{\"number\":123}" error:nil];
    
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:data destinationObject:object mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.boolString, is(equalTo(@"123")));
    [operation release];
}

- (void)testShouldFailTheMappingOperationIfKeyValueValidationSetsAnError {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"boolString", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    NSDictionary* dictionary = [NSDictionary dictionaryWithObject:@"FAIL" forKey:@"boolString"];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(NO)));
    assertThat(error, isNot(nilValue()));
    [operation release];
}

- (void)testShouldNotSetTheAttributeIfKeyValueValidationReturnsNo {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"boolString", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    object.boolString = @"should not change";
    NSDictionary* dictionary = [NSDictionary dictionaryWithObject:@"REJECT" forKey:@"boolString"];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.boolString, is(equalTo(@"should not change")));
    [operation release];
}

#pragma mark - TimeZone Handling

- (void)testShouldMapAUTCDateWithoutChangingTheTimeZone {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"date", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    NSDictionary* dictionary = [NSDictionary dictionaryWithObject:@"2011-07-07T04:35:28Z" forKey:@"date"];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.date, isNot(nilValue()));
    assertThat([object.date description], is(equalTo(@"2011-07-07 04:35:28 +0000")));
    [operation release];
}

- (void)testShouldMapASimpleDateStringAppropriately {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"date", nil];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    NSDictionary* dictionary = [NSDictionary dictionaryWithObject:@"08/09/2011" forKey:@"date"];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.date, isNot(nilValue()));
    assertThat([object.date description], is(equalTo(@"2011-08-09 00:00:00 +0000")));
    [operation release];
}

- (void)testShouldMapAStringIntoTheLocalTimeZone {
    NSTimeZone *EDTTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"EDT"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
    dateFormatter.dateFormat = @"MM-dd-yyyy";
    dateFormatter.timeZone = EDTTimeZone;
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapAttributes:@"date", nil];
    mapping.dateFormatters = [NSArray arrayWithObject:dateFormatter];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    NSDictionary* dictionary = [NSDictionary dictionaryWithObject:@"11-27-1982" forKey:@"date"];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.date, isNot(nilValue()));
    // Since there is no time date, our description will be midnight + UTC offset (5 hours)
    assertThat([object.date description], is(equalTo(@"1982-11-27 05:00:00 +0000")));
    [operation release];
}

- (void)testShouldMapADateToAStringUsingThePreferredDateFormatter {
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping mapKeyPath:@"date" toAttribute:@"boolString"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
    dateFormatter.dateFormat = @"MM-dd-yyyy";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    TestMappable* object = [[[TestMappable alloc] init] autorelease];
    object.date = [dateFormatter dateFromString:@"11-27-1982"];
    mapping.preferredDateFormatter = dateFormatter;
    TestMappable *newObject = [TestMappable new];
    RKObjectMappingOperation* operation = [[RKObjectMappingOperation alloc] initWithSourceObject:object destinationObject:newObject mapping:mapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(newObject.boolString, is(equalTo(@"11-27-1982")));
}

- (void)testShouldLogADebugMessageIfTheRelationshipMappingTargetsAnArrayOfArrays {
    // Create a dictionary with a dictionary containing an array
    // Use keyPath to traverse to the collection and target a hasMany
    id data = RKSpecParseFixture(@"ArrayOfNestedDictionaries.json");
    RKObjectMapping *objectMapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    [objectMapping mapKeyPath:@"name" toAttribute:@"stringTest"];
    RKObjectMapping *relationshipMapping = [RKObjectMapping mappingForClass:[RKMappableAssociation class]];
    [relationshipMapping mapKeyPath:@"title" toAttribute:@"testString"];
    [objectMapping mapKeyPath:@"mediaGroups.contents" toRelationship:@"hasMany" withMapping:relationshipMapping];
    RKMappableObject *targetObject = [[RKMappableObject new] autorelease];    
    RKLogToComponentWithLevelWhileExecutingBlock(lcl_cRestKitObjectMapping, RKLogLevelDebug, ^ {
        RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:data 
                                                                                   destinationObject:targetObject mapping:objectMapping];
        NSError *error = nil;
        [operation performMapping:&error];
    });
}

@end
