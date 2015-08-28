//
//  RKObjectMappingOperationTest.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
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
#import "RKMappingErrors.h"
#import "RKMappableObject.h"
#import "RKMappableAssociation.h"
#import "RKObjectMappingOperationDataSource.h"
#import "RKTestAddress.h"
#import "RKTestUser.h"

@interface TestMappable : NSObject {
    NSURL *_url;
    NSString *_boolString;
    NSDate *_date;
    NSOrderedSet *_orderedSet;
    NSArray *_array;
}

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *boolString;
@property (nonatomic, strong) NSNumber *boolNumber;
@property (nonatomic, strong) NSNumber *number;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSOrderedSet *orderedSet;
@property (nonatomic, strong) NSArray *array;

@end

@implementation TestMappable

@synthesize url = _url;
@synthesize boolString = _boolString;
@synthesize boolNumber = _boolNumber;
@synthesize date = _date;
@synthesize orderedSet = _orderedSet;
@synthesize array = _array;

- (BOOL)validateBoolString:(id *)ioValue error:(NSError **)outError
{
    if ([(NSObject *)*ioValue isKindOfClass:[NSString class]] && [(NSString *)*ioValue isEqualToString:@"FAIL"]) {
        *outError = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorUnmappableRepresentation userInfo:nil];
        return NO;
    } else if ([(NSObject *)*ioValue isKindOfClass:[NSString class]] && [(NSString *)*ioValue isEqualToString:@"REJECT"]) {
        return NO;
    } else if ([(NSObject *)*ioValue isKindOfClass:[NSString class]] && [(NSString *)*ioValue isEqualToString:@"MODIFY"]) {
        *ioValue = @"modified value";
        return YES;
    }

    return YES;
}

@end

@interface RKObjectMappingOperationTest : RKTestCase {

}

@end

@implementation RKObjectMappingOperationTest

- (void)testShouldNotUpdateEqualURLProperties
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"url"]];
    NSURL *url1 = [NSURL URLWithString:@"http://www.restkit.org"];
    NSURL *url2 = [NSURL URLWithString:@"http://www.restkit.org"];
    assertThatBool(url1 == url2, is(equalToBool(NO)));
    TestMappable *object = [[TestMappable alloc] init];
    [object setUrl:url1];
    NSDictionary *dictionary = @{@"url": url2};

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation start];
    BOOL success = (operation.error == nil);
    assertThatBool(success, is(equalToBool(YES)));
    assertThatBool(object.url == url1, is(equalToBool(YES)));
}

- (void)testShouldSuccessfullyMapBoolsToStrings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"boolString"]];
    TestMappable *object = [[TestMappable alloc] init];

    NSData *data = [@"{\"boolString\":true}" dataUsingEncoding:NSUTF8StringEncoding];
    id deserializedObject = [RKMIMETypeSerialization objectFromData:data MIMEType:RKMIMETypeJSON error:nil];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:deserializedObject destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation start];
    BOOL success = (operation.error == nil);
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.boolString, is(equalTo(@"true")));
}

- (void)testShouldSuccessfullyMapTrueBoolsToNSNumbers
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"boolNumber"]];
    TestMappable *object = [[TestMappable alloc] init];

    NSData *data = [@"{\"boolNumber\":true}" dataUsingEncoding:NSUTF8StringEncoding];
    id deserializedObject = [RKMIMETypeSerialization objectFromData:data MIMEType:RKMIMETypeJSON error:nil];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:deserializedObject destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation start];
    BOOL success = (operation.error == nil);
    assertThatBool(success, is(equalToBool(YES)));
    assertThatInt([object.boolNumber intValue], is(equalToInt(1)));
}

- (void)testShouldSuccessfullyMapFalseBoolsToNSNumbers
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"boolNumber"]];
    TestMappable *object = [[TestMappable alloc] init];

    NSData *data = [@"{\"boolNumber\":false}" dataUsingEncoding:NSUTF8StringEncoding];
    id deserializedObject = [RKMIMETypeSerialization objectFromData:data MIMEType:RKMIMETypeJSON error:nil];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:deserializedObject destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation start];
    BOOL success = (operation.error == nil);
    assertThatBool(success, is(equalToBool(YES)));
    assertThatInt([object.boolNumber intValue], is(equalToInt(0)));
}

- (void)testShouldSuccessfullyMapNumbersToStrings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"number" toKeyPath:@"boolString"]];
    TestMappable *object = [[TestMappable alloc] init];

    NSData *data = [@"{\"number\":123}" dataUsingEncoding:NSUTF8StringEncoding];
    id deserializedObject = [RKMIMETypeSerialization objectFromData:data MIMEType:RKMIMETypeJSON error:nil];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:deserializedObject destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation start];
    BOOL success = (operation.error == nil);
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.boolString, is(equalTo(@"123")));
}

- (void)testShouldSuccessfullyMapLongIntegerStringsToNumbers
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"numberString" toKeyPath:@"number"]];
    TestMappable *object = [[TestMappable alloc] init];

    NSData *data = [@"{\"numberString\":\"69726278940360707\"}" dataUsingEncoding:NSUTF8StringEncoding];
    id deserializedObject = [RKMIMETypeSerialization objectFromData:data MIMEType:RKMIMETypeJSON error:nil];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:deserializedObject destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation start];
    BOOL success = (operation.error == nil);
    assertThatBool(success, is(equalToBool(YES)));
    assertThatUnsignedLongLong([object.number unsignedLongLongValue], is(equalToUnsignedLongLong(69726278940360707)));
    
}

- (void)testShouldSuccessfullyMapFloatingPointNumberStringsToNumbers
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"numberString" toKeyPath:@"number"]];
    TestMappable *object = [[TestMappable alloc] init];

    NSData *data = [@"{\"numberString\":\"1234.5678\"}" dataUsingEncoding:NSUTF8StringEncoding];
    id deserializedObject = [RKMIMETypeSerialization objectFromData:data MIMEType:RKMIMETypeJSON error:nil];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:deserializedObject destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation start];
    BOOL success = (operation.error == nil);
    assertThatBool(success, is(equalToBool(YES)));
    assertThatDouble([object.number doubleValue], is(equalToDouble(1234.5678)));
    
}

- (void)testShouldSuccessfullyMapPropertiesBeforeKeyPathAttributes
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    RKAttributeMapping *nestedCityMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"nested.city" toKeyPath:@"address.city"];
    [userMapping addPropertyMapping:nameMapping];
    [userMapping addPropertyMapping:nestedCityMapping];

    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKAttributeMapping *cityMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addPropertyMapping:cityMapping];

    RKRelationshipMapping *hasOneMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addPropertyMapping:hasOneMapping];

    NSData *data = [@"{\"name\": \"Blake Watters\",\"address\": {\"city\": \"Carrboro\"},\"nested\": {\"city\": \"New York\"}}" dataUsingEncoding:NSUTF8StringEncoding];
    id deserializedObject = [RKMIMETypeSerialization objectFromData:data MIMEType:RKMIMETypeJSON error:nil];

    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:deserializedObject destinationObject:user mapping:userMapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation start];
    BOOL success = (operation.error == nil);
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.address.city, is(equalTo(@"New York")));
}

- (void)testShouldSuccessfullyMapArraysToOrderedSets
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"numbers" toKeyPath:@"orderedSet"]];
    TestMappable *object = [[TestMappable alloc] init];

    NSData *data = [@"{\"numbers\":[1, 2, 3]}" dataUsingEncoding:NSUTF8StringEncoding];
    id deserializedObject = [RKMIMETypeSerialization objectFromData:data MIMEType:RKMIMETypeJSON error:nil];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:deserializedObject destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    NSOrderedSet *expectedSet = [NSOrderedSet orderedSetWithObjects:@1, @2, @3, nil];
    assertThat(object.orderedSet, is(equalTo(expectedSet)));
}

- (void)testShouldSuccessfullyMapOrderedSetsToArrays
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"orderedSet" toKeyPath:@"array"]];
    TestMappable *object = [[TestMappable alloc] init];

    TestMappable *data = [[TestMappable alloc] init];
    data.orderedSet = [NSOrderedSet orderedSetWithObjects:@1, @2, @3, nil];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:data destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    NSArray *expectedArray = @[@1, @2, @3];
    assertThat(object.array, is(equalTo(expectedArray)));
}

- (void)testShouldFailTheMappingOperationIfKeyValueValidationSetsAnError
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"boolString"]];
    TestMappable *object = [[TestMappable alloc] init];
    NSDictionary *dictionary = @{@"boolString": @"FAIL"};
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(NO)));
    assertThat(error, isNot(nilValue()));
}

- (void)testShouldFailWithoutThrowingIfMappingAnInvalidKeyPath
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromDictionary:@{ @"object.number": @"number" }];
    TestMappable *object = [[TestMappable alloc] init];
    NSDictionary *dictionary = @{@"object": @"a string instead of a dictionary"};
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(NO)));
    assertThat(error.domain, is(equalTo(RKErrorDomain)));
    assertThatInteger(error.code, is(equalToInteger(RKMappingErrorUnmappableRepresentation)));
}

- (void)testShouldNotSetTheAttributeIfKeyValueValidationReturnsNo
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"boolString"]];
    TestMappable *object = [[TestMappable alloc] init];
    object.boolString = @"should not change";
    NSDictionary *dictionary = @{@"boolString": @"REJECT"};
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.boolString, is(equalTo(@"should not change")));
}

- (void)testModifyingValueWithinKeyValueValidationIsRespected
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"boolString"]];
    TestMappable *object = [[TestMappable alloc] init];
    NSDictionary *dictionary = @{@"boolString": @"MODIFY"};
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.boolString, is(equalTo(@"modified value")));
}

#pragma mark - TimeZone Handling

- (void)testShouldMapAUTCDateWithoutChangingTheTimeZone
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"date"]];
    TestMappable *object = [[TestMappable alloc] init];
    NSDictionary *dictionary = @{@"date": @"2011-07-07T04:35:28Z"};
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.date, isNot(nilValue()));
    assertThat([object.date description], is(equalTo(@"2011-07-07 04:35:28 +0000")));
}

- (void)testShouldMapAUnixTimestampStringAppropriately
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"date"]];
    TestMappable *object = [[TestMappable alloc] init];
    NSDictionary *dictionary = @{@"date": @"457574400"};
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.date, isNot(nilValue()));
    assertThat([object.date description], is(equalTo(@"1984-07-02 00:00:00 +0000")));
}

- (void)testShouldMapASimpleDateStringAppropriately
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"date"]];
    TestMappable *object = [[TestMappable alloc] init];
    NSDictionary *dictionary = @{@"date": @"08/09/2011"};
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.date, isNot(nilValue()));
    assertThat([object.date description], is(equalTo(@"2011-08-09 00:00:00 +0000")));
}

// NOTE: The timestamp used here is missing seconds
- (void)testShouldMapAISODateStringAppropriately
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"date"]];
    TestMappable *object = [[TestMappable alloc] init];
    NSDictionary *dictionary = @{@"date": @"2011-08-09T00:00Z"};
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.date, isNot(nilValue()));
    assertThat([object.date description], is(equalTo(@"2011-08-09 00:00:00 +0000")));
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)testShouldMapAStringIntoTheLocalTimeZone
{
    NSTimeZone *EDTTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"EDT"];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"MM-dd-yyyy";
    dateFormatter.timeZone = EDTTimeZone;
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addAttributeMappingsFromArray:@[@"date"]];
    mapping.dateFormatters = @[dateFormatter];
    TestMappable *object = [[TestMappable alloc] init];
    NSDictionary *dictionary = @{@"date": @"11-27-1982"};
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:object mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(object.date, isNot(nilValue()));
    // Since there is no time date, our description will be midnight + UTC offset (5 hours)
    assertThat([object.date description], is(equalTo(@"1982-11-27 05:00:00 +0000")));
}

- (void)testShouldMapADateToAStringUsingThePreferredDateFormatter
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"date" toKeyPath:@"boolString"]];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"MM-dd-yyyy";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    TestMappable *object = [[TestMappable alloc] init];
    object.date = [dateFormatter dateFromString:@"11-27-1982"];
    mapping.preferredDateFormatter = dateFormatter;
    TestMappable *newObject = [TestMappable new];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:object destinationObject:newObject mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(newObject.boolString, is(equalTo(@"11-27-1982")));
}

#pragma clang diagnostic pop

- (void)testShouldMapAStringToAURL
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"url" toKeyPath:@"url"]];
    TestMappable *object = [[TestMappable alloc] init];
    object.url = [NSURL URLWithString:@"http://www.restkit.org"];
    TestMappable *newObject = [TestMappable new];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:object destinationObject:newObject mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(newObject.url, is(equalTo([NSURL URLWithString:@"http://www.restkit.org"])));

}

- (void)testShouldLogADebugMessageIfTheRelationshipMappingTargetsAnArrayOfArrays
{
    // Create a dictionary with a dictionary containing an array
    // Use keyPath to traverse to the collection and target a hasMany
    id data = [RKTestFixture parsedObjectWithContentsOfFixture:@"ArrayOfNestedDictionaries.json"];
    RKObjectMapping *objectMapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    [objectMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"stringTest"]];
    RKObjectMapping *relationshipMapping = [RKObjectMapping mappingForClass:[RKMappableAssociation class]];
    [relationshipMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"title" toKeyPath:@"testString"]];
    [objectMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"mediaGroups.contents" toKeyPath:@"hasMany" withMapping:relationshipMapping]];;
    RKMappableObject *targetObject = [RKMappableObject new];
    RKLogToComponentWithLevelWhileExecutingBlock(RKlcl_cRestKitObjectMapping, RKLogLevelDebug, ^ {
        RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:data
                                                                                   destinationObject:targetObject mapping:objectMapping];
        RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
        operation.dataSource = dataSource;
        NSError *error = nil;
        [operation performMapping:&error];
    });
}

- (void)testMappingSimpleAttributesDoesNotTriggerDataSourceAssertion
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMappingsFromArray:@[@"boolString"]];
    TestMappable *object = [TestMappable new];
    object.boolString = @"test";
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:object destinationObject:dictionary mapping:mapping];
    NSException *exception = nil;
    @try {
        [operation start];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        expect(exception).to.beNil();
    }
}

- (void)testCancellationOfMapperOperation
{
    RKObjectMapping *childMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [childMapping addAttributeMappingsFromArray:@[@"name"]];
    
    RKObjectMapping *parentMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [parentMapping addAttributeMappingsFromArray:@[@"name"]];
    [parentMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"children" toKeyPath:@"friends" withMapping:childMapping]];
    NSDictionary *mappingsDictionary = @{ @"parents": parentMapping };
    
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"benchmark_parents_and_children.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:JSON mappingsDictionary:mappingsDictionary];
    [operationQueue addOperation:mapper];
    [mapper cancel];
    [operationQueue waitUntilAllOperationsAreFinished];
    expect([mapper isCancelled]).to.equal(YES);
    expect(mapper.error).to.beNil();
    expect(mapper.mappingResult).to.beNil();
}

- (void)testMappingRootKeyToDictionary
{
    NSDictionary *representation = @{ @"MyObject": @{ @"ObjectAttribute1": @{} }, @"MyRootString": @"SomeString" };
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMappingsFromDictionary:@{ @"MyRootString": @"MyRootString" }];
    
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:nil mapping:mapping];
    mappingOperation.dataSource = dataSource;
    BOOL success = [mappingOperation performMapping:nil];
    expect(success).to.equal(YES);
    expect([mappingOperation.destinationObject isKindOfClass:[NSMutableDictionary class]]).to.equal(YES);
    expect([mappingOperation.destinationObject valueForKeyPath:@"MyRootString"]).to.equal(@"SomeString");
}

- (void)testThatOneToOneRelationshipOfHasManyDoesNotHaveIncorrectCollectionIndexMetadataKey
{
    NSDictionary *representation = @{ @"name": @"Blake", @"friend": @{ @"name": @"jeff" } };
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.mapping.collectionIndex": @"luckyNumber" }];
    [userMapping addRelationshipMappingWithSourceKeyPath:@"friend" mapping:userMapping];

    NSDictionary *metadata = @{ @"mapping": @{ @"collectionIndex": @25 } };
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:nil mapping:userMapping metadataList:@[metadata]];
    mappingOperation.dataSource = dataSource;
    BOOL success = [mappingOperation performMapping:nil];
    expect(success).to.equal(YES);

    RKTestUser *blake = mappingOperation.destinationObject;
    expect(blake).notTo.beNil();
    expect(blake.name).to.equal(@"Blake");
    expect(blake.luckyNumber).to.equal(@25);
    expect(blake.friend).notTo.beNil();
    expect(blake.friend.luckyNumber).to.beNil();
}

- (void)testThatCustomTransformerOnPropertyMappingIsInvoked
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[TestMappable class]];
    RKPropertyMapping *propertyMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"url" toKeyPath:@"url"];
    propertyMapping.valueTransformer = [RKBlockValueTransformer valueTransformerWithValidationBlock:nil transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputClass, NSError *__autoreleasing *error) {
        *outputValue = [inputValue URLByAppendingPathComponent:@"test"];
        return YES;
    }];
    [mapping addPropertyMapping:propertyMapping];
    TestMappable *object = [[TestMappable alloc] init];
    object.url = [NSURL URLWithString:@"http://www.restkit.org"];
    TestMappable *newObject = [TestMappable new];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:object destinationObject:newObject mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(newObject.url, is(equalTo([NSURL URLWithString:@"http://www.restkit.org/test"])));
}

@end
