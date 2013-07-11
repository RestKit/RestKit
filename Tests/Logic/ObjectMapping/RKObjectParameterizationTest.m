//
//  RKObjectParameterizationTest.m
//  RestKit
//
//  Created by Jeremy Ellison on 5/9/11.
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
#import "RKObjectParameterization.h"
#import "RKMIMETypeSerialization.h"
#import "RKMappableObject.h"
#import "RKDynamicMapping.h"
#import "RKMappingErrors.h"
#import "RKHuman.h"
#import "RKTestUser.h"
#import "RKCat.h"

@interface RKMIMETypeSerialization ()
@property (nonatomic, strong) NSMutableArray *registrations;

+ (RKMIMETypeSerialization *)sharedSerialization;
- (void)addRegistrationsForKnownSerializations;
@end

@interface RKObjectParameterizationTest : RKTestCase
@end

@implementation RKObjectParameterizationTest

- (void)setUp
{
    [RKTestFactory setUp];
    
    [RKMIMETypeSerialization sharedSerialization].registrations = [NSMutableArray array];
    [[RKMIMETypeSerialization sharedSerialization] addRegistrationsForKnownSerializations];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testShouldSerializeToFormEncodedData
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    
    // URL Encode
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    expect(error).to.beNil();
    expect(string).to.equal(@"key1-form-name=value1&key2-form-name=value2");
}

- (void)testShouldSerializeADate
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDate dateWithTimeIntervalSince1970:0], @"date", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"date" toKeyPath:@"date-form-name"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    expect(error).to.beNil();
    expect(parameters[@"date-form-name"]).to.equal(@"1970-01-01T00:00:00Z");
}

- (void)testShouldSerializeADateToAStringUsingThePreferredDateFormatter
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDate dateWithTimeIntervalSince1970:0], @"date", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"MM/dd/yyyy";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    mapping.preferredDateFormatter = dateFormatter;
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"date" toKeyPath:@"date-form-name"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    expect(error).to.beNil();
    expect(string).to.equal(@"date-form-name=01/01/1970&key1-form-name=value1");
}

- (void)testShouldSerializeADateToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDate dateWithTimeIntervalSince1970:0], @"date", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"date" toKeyPath:@"date-form-name"]];

    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    expect(error).to.beNil();
    expect(string).to.equal(@"{\"key1-form-name\":\"value1\",\"date-form-name\":\"1970-01-01T00:00:00Z\"}");
}

- (void)testShouldSerializeNSDecimalNumberAttributesToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDecimalNumber decimalNumberWithString:@"18274191731731.4557723623"], @"number", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"number" toKeyPath:@"number-form-name"]];
        
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    expect(error).to.beNil();
    expect(string).to.equal(@"{\"key1-form-name\":\"value1\",\"number-form-name\":\"18274191731731.4557723623\"}");
}

- (void)testShouldSerializeRelationshipsToo
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2",
                            [NSArray arrayWithObjects:
                             [NSDictionary dictionaryWithObjectsAndKeys:@"relationship1Value1", @"relatioship1Key1", nil],
                             [NSDictionary dictionaryWithObjectsAndKeys:@"relationship1Value2", @"relatioship1Key1", nil], nil], @"relationship1",
                            [NSDictionary dictionaryWithObjectsAndKeys:@"subValue1", @"subKey1", nil], @"relationship2",
                            nil];

    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"relationship1.relatioship1Key1" toKeyPath:@"relationship1-form-name[r1k1]"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"relationship2.subKey1" toKeyPath:@"relationship2-form-name[subKey1]"]];

    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    expect(error).to.beNil();
    expect(string).to.equal(@"key1-form-name=value1&key2-form-name=value2&relationship1-form-name[r1k1][]=relationship1Value1&relationship1-form-name[r1k1][]=relationship1Value2&relationship2-form-name[subKey1]=subValue1");
}

- (void)testShouldSerializeToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    expect(error).to.beNil();
    expect(string).to.equal(@"{\"key2-form-name\":\"value2\",\"key1-form-name\":\"value1\"}");
}

- (void)testShouldSetReturnEmptyDictionaryIfItDoesNotFindAnythingToSerialize
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key12123" toKeyPath:@"key1-form-name"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    expect(error).to.beNil();
    expect(parameters).to.equal(@{});
}

- (void)testEmptyParameterizationRespectsRootKeyPath
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key12123" toKeyPath:@"key1-form-name"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:@"root" method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    expect(error).to.beNil();
    expect(parameters).to.equal(@{@"root":@{}});
}

- (void)testShouldSerializeNestedObjectsContainingDatesToJSON
{
    RKMappableObject *object = [RKMappableObject new];
    object.stringTest = @"The string";
    RKMappableAssociation *association = [RKMappableAssociation new];
    association.date = [NSDate dateWithTimeIntervalSince1970:0];
    object.hasOne = association;

    // Setup object mappings
    RKObjectMapping *objectMapping = [RKObjectMapping requestMapping];
    [objectMapping addAttributeMappingsFromArray:@[ @"stringTest" ]];
    RKObjectMapping *relationshipMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [relationshipMapping addAttributeMappingsFromArray:@[ @"date" ]];
    [objectMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"hasOne" toKeyPath:@"hasOne" withMapping:relationshipMapping]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:objectMapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    // Encodes differently on iOS / OS X
    #if TARGET_OS_IPHONE
    expect(string).to.equal(@"{\"stringTest\":\"The string\",\"hasOne\":{\"date\":\"1970-01-01T00:00:00Z\"}}");
    #else
    expect(string).to.equal(@"{\"hasOne\":{\"date\":\"1970-01-01T00:00:00Z\"},\"stringTest\":\"The string\"}");
    #endif
}

- (void)testShouldEncloseTheSerializationInAContainerIfRequested
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:@"stuff" method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    expect(parameters[@"stuff"][@"key2-form-name"]).to.equal(@"value2");
    expect(parameters[@"stuff"][@"key1-form-name"]).to.equal(@"value1");
}

- (void)testShouldSerializeToManyRelationships
{
    RKMappableObject *object = [RKMappableObject new];
    object.stringTest = @"The string";
    RKMappableAssociation *association = [RKMappableAssociation new];
    association.date = [NSDate dateWithTimeIntervalSince1970:0];
    object.hasMany = [NSSet setWithObject:association];

    // Setup object mappings
    RKObjectMapping *objectMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [objectMapping addAttributeMappingsFromArray:@[@"stringTest"]];
    RKObjectMapping *relationshipMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [relationshipMapping addAttributeMappingsFromArray:@[@"date"]];
    [objectMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"hasMany" toKeyPath:@"hasMany" withMapping:relationshipMapping]];

    // Serialize
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:objectMapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    expect(string).to.equal(@"{\"hasMany\":[{\"date\":\"1970-01-01T00:00:00Z\"}],\"stringTest\":\"The string\"}");
}

- (void)testShouldSerializeAnNSNumberContainingABooleanToTrueFalseIfRequested
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSNumber numberWithBool:YES], @"boolean", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKAttributeMapping *attributeMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"boolean" toKeyPath:@"boolean-value"];
    [mapping addPropertyMapping:attributeMapping];    
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    expect(error).to.beNil();
    expect(string).to.equal(@"{\"boolean-value\":true}");
}

- (void)testShouldSerializeANSOrderedSetToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1",
                            [NSOrderedSet orderedSetWithObjects:@"setElementOne", @"setElementTwo", @"setElementThree", nil], @"set",
                            nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"set" toKeyPath:@"set-form-name"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    expect(error).to.beNil();
    expect(string).to.equal(@"{\"key1-form-name\":\"value1\",\"set-form-name\":[\"setElementOne\",\"setElementTwo\",\"setElementThree\"]}");
}

- (void)testShouldSerializeAnNSSetToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1",
                            [NSSet setWithObjects:@"setElementOne", nil], @"set",
                            nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"set" toKeyPath:@"set-form-name"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    expect(error).to.beNil();
    expect(string).to.equal(@"{\"key1-form-name\":\"value1\",\"set-form-name\":[\"setElementOne\"]}");
}

- (void)testParameterizationOfAttributesNestedByKeyPath
{
    NSDictionary *object = @{ @"name" : @"Blake Watters", @"occupation" : @"Hacker" };
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"user.name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"occupation" toKeyPath:@"user.job"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    NSDictionary *expected = @{@"user": @{@"name": @"Blake Watters", @"job": @"Hacker"}};
    expect(parameters).to.equal(expected);
}

- (void)testParameterizationOfAttributesDeeplyNestedByKeyPathToFormEncoded
{
    NSDictionary *object = @{ @"name" : @"Blake Watters", @"occupation" : @"Hacker" };
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"user.anotherKeyPath.name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"occupation" toKeyPath:@"user.anotherKeyPath.another.job"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    NSDictionary *expected = @{@"user": @{@"anotherKeyPath": @{@"name": @"Blake Watters", @"another": @{ @"job": @"Hacker"}}}};
    expect(parameters).to.equal(expected);
}

- (void)testParameterizationOfPrimitiveBooleansToJSONBooleans
{
    NSDictionary *object = @{ @"name" : @"Blake Watters", @"isHacker" : @YES };
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"isHacker" toKeyPath:@"isHacker"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    NSDictionary *expected = @ {@"name": @"Blake Watters", @"isHacker": @YES };
    expect(parameters).to.equal(expected);
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    expect(error).to.beNil();
    expect(string).to.equal(@"{\"name\":\"Blake Watters\",\"isHacker\":true}");
}

- (void)testParameterizationOfBooleanPropertiesToJSONBooleansFromObjectProperties
{
    RKMappableObject *object = [RKMappableObject new];
    object.stringTest = @"Whatever";
    object.isValid = NO;
    object.numberTest = @YES;
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"stringTest" toKeyPath:@"name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"isValid" toKeyPath:@"is_valid"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"numberTest" toKeyPath:@"is_boolean"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    expect(error).to.beNil();
    // Unordered dictionary handling
    NSArray *serializations = @[ @"{\"is_valid\":0,\"name\":\"Whatever\",\"is_boolean\":true}", @"{\"name\":\"Whatever\",\"is_valid\":0,\"is_boolean\":true}" ];
    expect(serializations).to.contain(string);
}

- (void)testParameterizationofBooleanPropertiesFromManagedObjectProperty
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.isHappy = [NSNumber numberWithBool:YES];
    human.name = @"Blake Watters";
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"isHappy" toKeyPath:@"happy"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:human requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    expect(error).to.beNil();
    expect(string).to.equal(@"{\"name\":\"Blake Watters\",\"happy\":true}");
}

- (void)testParameterizationofBooleanPropertiesFromManagedObjectPropertyWithFalseValue
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.isHappy = [NSNumber numberWithBool:NO];
    human.name = @"Blake Watters";
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"isHappy" toKeyPath:@"happy"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:human requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    expect(error).to.beNil();
    expect(string).to.equal(@"{\"name\":\"Blake Watters\",\"happy\":false}");
}

- (void)testSerializingWithDynamicNestingAttribute
{
    NSDictionary *object = @{ @"name" : @"blake", @"occupation" : @"Hacker" };
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addAttributeMappingToKeyOfRepresentationFromAttribute:@"name"];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"(name).name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"occupation" toKeyPath:@"(name).job"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    NSDictionary *expected = @{@"blake": @{@"name": @"blake", @"job": @"Hacker"}};
    expect(parameters).to.equal(expected);
}

- (void)testParameterizationOfCoreDataEntityWithDateToNestedKeypath
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.birthday = [NSDate dateWithTimeIntervalSince1970:0];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"birthday" toKeyPath:@"nestedPath.birthday"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil method:RKRequestMethodAny];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:human requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    expect(error).to.beNil();
    expect(string).to.equal(@"{\"nestedPath\":{\"birthday\":\"1970-01-01T00:00:00Z\"}}");
}

@end

#pragma mark - Dynamic Request Paramterization

typedef enum {
    RKSearchByFlightNumberMode = 1,
    RKSearchByRouteMode = 2,
    RKSearcyByOtherMode
} RKFlightSearchMode;

@interface RKDynamicParameterizationFlightSearch : NSObject
@property (nonatomic, assign) RKFlightSearchMode mode;
@property (nonatomic, copy) NSNumber *airlineID;
@property (nonatomic, copy) NSNumber *flightNumber;
@property (nonatomic, copy) NSNumber *departureAirportID;
@property (nonatomic, copy) NSNumber *arrivalAirportID;
@property (nonatomic, copy) NSDate *departureDate;
@end

@implementation RKDynamicParameterizationFlightSearch
@end

@interface RKDynamicParameterizationTest : RKTestCase
@end

@implementation RKDynamicParameterizationTest

- (void)testParameterizationUsingDynamicMapping
{
    NSDictionary *expectedFlightNumberParameters = @{ @"flight_search": @{ @"flight_number": @1234, @"airline_id": @5678 } };
    NSDictionary *expectedRouteParameters = @{ @"flight_search": @{ @"departure_airport_id": @25, @"arrival_airport_id": @66, @"airline_id": @5678 } };
    
    RKObjectMapping *flightNumberMapping = [RKObjectMapping requestMapping];
    [flightNumberMapping addAttributeMappingsFromDictionary:@{ @"flightNumber": @"flight_number", @"airlineID": @"airline_id" }];
    RKObjectMapping *routeMapping = [RKObjectMapping requestMapping];
    [routeMapping addAttributeMappingsFromDictionary:@{ @"airlineID": @"airline_id", @"departureAirportID": @"departure_airport_id", @"arrivalAirportID": @"arrival_airport_id" }];
    
    RKDynamicMapping *flightSearchMapping = [RKDynamicMapping new];
    [flightSearchMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"mode" expectedValue:@(RKSearchByFlightNumberMode) objectMapping:flightNumberMapping]];
    [flightSearchMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"mode" expectedValue:@(RKSearchByRouteMode) objectMapping:routeMapping]];
    
    RKDynamicParameterizationFlightSearch *flightSearch = [RKDynamicParameterizationFlightSearch new];
    flightSearch.airlineID = @5678;
    flightSearch.flightNumber = @1234;
    flightSearch.departureAirportID = @25;
    flightSearch.arrivalAirportID = @66;
    
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:flightSearchMapping
                                                                                   objectClass:[RKDynamicParameterizationFlightSearch class]
                                                                                   rootKeyPath:@"flight_search"
                                                                                        method:RKRequestMethodAny];
    NSError *error = nil;
    NSDictionary *parameters = nil;
    
    // Test generation of Flight Number parameters
    flightSearch.mode = RKSearchByFlightNumberMode;
    parameters = [RKObjectParameterization parametersWithObject:flightSearch requestDescriptor:requestDescriptor error:&error];
    expect(parameters).to.equal(expectedFlightNumberParameters);
    
    // Test generation of Route paramters
    flightSearch.mode = RKSearchByRouteMode;
    parameters = [RKObjectParameterization parametersWithObject:flightSearch requestDescriptor:requestDescriptor error:&error];
    expect(parameters).to.equal(expectedRouteParameters);
    
    // Test non-match
    flightSearch.mode = RKSearcyByOtherMode;
    parameters = [RKObjectParameterization parametersWithObject:flightSearch requestDescriptor:requestDescriptor error:&error];
    expect(parameters).to.beNil();
    expect(error).notTo.beNil();
    expect(error.code).to.equal(RKMappingErrorUnableToDetermineMapping);
}

- (void)testDynamicParameterizationIncludingADate
{
    RKObjectMapping *concreteMapping = [RKObjectMapping requestMapping];
    [concreteMapping addAttributeMappingsFromDictionary:@{ @"departureDate": @"departure_date" }];
    
    RKDynamicMapping *flightSearchMapping = [RKDynamicMapping new];
    [flightSearchMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"mode" expectedValue:@(RKSearchByFlightNumberMode) objectMapping:concreteMapping]];
    
    RKDynamicParameterizationFlightSearch *flightSearch = [RKDynamicParameterizationFlightSearch new];
    flightSearch.airlineID = @5678;
    flightSearch.flightNumber = @1234;
    flightSearch.departureAirportID = @25;
    flightSearch.arrivalAirportID = @66;
    flightSearch.mode = RKSearchByFlightNumberMode;
    flightSearch.departureDate = [NSDate dateWithTimeIntervalSince1970:0];
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:flightSearchMapping
                                                                                   objectClass:[RKDynamicParameterizationFlightSearch class]
                                                                                   rootKeyPath:@"flight_search"
                                                                                        method:RKRequestMethodAny];
    NSError *error = nil;
    NSDictionary *parameters = nil;
    
    // Test generation of Flight Number parameters    
    parameters = [RKObjectParameterization parametersWithObject:flightSearch requestDescriptor:requestDescriptor error:&error];
    NSDictionary *expectedParameters = @{ @"flight_search": @{ @"departure_date": @"1970-01-01T00:00:00Z" }};
    expect(parameters).to.equal(expectedParameters);
}

- (void)testShouldSerializeHasOneRelatioshipsToJSON
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping addAttributeMappingsFromArray:@[@"city", @"state"]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping]];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake Watters";
    RKTestAddress *address = [RKTestAddress new];
    address.state = @"North Carolina";
    user.address = address;

    RKObjectMapping *serializationMapping = [userMapping inverseMapping];
    NSDictionary *params = [RKObjectParameterization parametersWithObject:user requestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestUser class] rootKeyPath:nil method:RKRequestMethodAny] error:nil];
    NSError *error = nil;
    NSString *JSON = [[NSString alloc] initWithData:[RKMIMETypeSerialization dataFromObject:params MIMEType:RKMIMETypeJSON error:nil] encoding:NSUTF8StringEncoding];
    assertThat(error, is(nilValue()));
    assertThat(JSON, is(equalTo(@"{\"name\":\"Blake Watters\",\"address\":{\"state\":\"North Carolina\"}}")));
}

- (void)testShouldSerializeHasManyRelationshipsToJSON
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping addAttributeMappingsFromArray:@[@"city", @"state"]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:addressMapping]];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake Watters";
    RKTestAddress *address1 = [RKTestAddress new];
    address1.city = @"Carrboro";
    RKTestAddress *address2 = [RKTestAddress new];
    address2.city = @"New York City";
    user.friends = [NSArray arrayWithObjects:address1, address2, nil];


    RKObjectMapping *serializationMapping = [userMapping inverseMapping];
    NSDictionary *params = [RKObjectParameterization parametersWithObject:user requestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestUser class] rootKeyPath:nil method:RKRequestMethodAny] error:nil];
    NSError *error = nil;
    NSString *JSON = [[NSString alloc] initWithData:[RKMIMETypeSerialization dataFromObject:params MIMEType:RKMIMETypeJSON error:nil] encoding:NSUTF8StringEncoding];
    assertThat(error, is(nilValue()));
    assertThat(JSON, is(equalTo(@"{\"name\":\"Blake Watters\",\"friends\":[{\"city\":\"Carrboro\"},{\"city\":\"New York City\"}]}")));
}

- (void)testShouldSerializeManagedHasManyRelationshipsToJSON
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectMapping *humanMapping = [RKObjectMapping mappingForClass:[RKHuman class]];
    [humanMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *catMapping = [RKObjectMapping mappingForClass:[RKCat class]];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catMapping]];

    RKHuman *blake = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    blake.name = @"Blake Watters";
    RKCat *asia = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    asia.name = @"Asia";
    RKCat *roy = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    roy.name = @"Roy";
    blake.cats = [NSSet setWithObjects:asia, roy, nil];

    RKObjectMapping *serializationMapping = [humanMapping inverseMapping];

    NSDictionary *params = [RKObjectParameterization parametersWithObject:blake requestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKHuman class] rootKeyPath:nil method:RKRequestMethodAny] error:nil];
    NSError *error = nil;
    NSDictionary *parsedJSON = [NSJSONSerialization JSONObjectWithData:[RKMIMETypeSerialization dataFromObject:params MIMEType:RKMIMETypeJSON error:nil] options:0 error:nil];
    assertThat(error, is(nilValue()));
    assertThat([parsedJSON valueForKey:@"name"], is(equalTo(@"Blake Watters")));
    NSArray *catNames = [[parsedJSON valueForKeyPath:@"cats.name"] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    assertThat(catNames, is(equalTo([NSArray arrayWithObjects:@"Asia", @"Roy", nil])));
}

- (void)testParameterizingHasManyRelationshipToNestedKeyPath
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping addAttributeMappingsFromArray:@[@"city", @"state"]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:addressMapping]];
    
    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake Watters";
    RKTestAddress *address1 = [RKTestAddress new];
    address1.city = @"Carrboro";
    RKTestAddress *address2 = [RKTestAddress new];
    address2.city = @"New York City";
    user.friends = [NSArray arrayWithObjects:address1, address2, nil];
    
    
    RKObjectMapping *requestMapping = [RKObjectMapping requestMapping];
    [requestMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKObjectMapping *cityMapping = [RKObjectMapping requestMapping];
    [cityMapping addAttributeMappingsFromArray:@[ @"city" ]];
    [requestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"cities.eastCoast" withMapping:cityMapping]];;
    NSDictionary *params = [RKObjectParameterization parametersWithObject:user requestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[RKTestUser class] rootKeyPath:nil method:RKRequestMethodAny] error:nil];
    NSError *error = nil;
    NSDictionary *parsedJSON = [NSJSONSerialization JSONObjectWithData:[RKMIMETypeSerialization dataFromObject:params MIMEType:RKMIMETypeJSON error:nil] options:0 error:nil];
    assertThat(error, is(nilValue()));
    assertThat(parsedJSON[@"name"], is(equalTo(@"Blake Watters")));
    assertThat([parsedJSON valueForKeyPath:@"cities.eastCoast.city"], hasItems(@"Carrboro", @"New York City", nil));
}

@end
