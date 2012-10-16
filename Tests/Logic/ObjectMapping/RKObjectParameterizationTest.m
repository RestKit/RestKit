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
    [RKMIMETypeSerialization sharedSerialization].registrations = [NSMutableArray array];
    [[RKMIMETypeSerialization sharedSerialization] addRegistrationsForKnownSerializations];
}

- (void)testShouldSerializeToFormEncodedData
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
    
    // URL Encode
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    expect(error).to.beNil();
    expect(string).to.equal(@"key2-form-name=value2&key1-form-name=value1");
}

- (void)testShouldSerializeADate
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDate dateWithTimeIntervalSince1970:0], @"date", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"date" toKeyPath:@"date-form-name"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    expect(error).to.beNil();
    expect(parameters[@"date-form-name"]).to.equal(@"1970-01-01 00:00:00 +0000");
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
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    expect(error).to.beNil();
    expect(string).to.equal(@"key1-form-name=value1&date-form-name=01/01/1970");
}

- (void)testShouldSerializeADateToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDate dateWithTimeIntervalSince1970:0], @"date", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"date" toKeyPath:@"date-form-name"]];

    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    expect(error).to.beNil();
    expect(string).to.equal(@"{\"key1-form-name\":\"value1\",\"date-form-name\":\"1970-01-01 00:00:00 +0000\"}");
}

- (void)testShouldSerializeNSDecimalNumberAttributesToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSDecimalNumber decimalNumberWithString:@"18274191731731.4557723623"], @"number", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"number" toKeyPath:@"number-form-name"]];
        
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
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
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    expect(error).to.beNil();
    #if TARGET_OS_IPHONE
    expect(string).to.equal(@"key1-form-name=value1&relationship1-form-name[r1k1][]=relationship1Value1&relationship1-form-name[r1k1][]=relationship1Value2&key2-form-name=value2&relationship2-form-name[subKey1]=subValue1");
    #else
    expect(string).to.equal(@"relationship1-form-name[r1k1][]=relationship1Value1&relationship1-form-name[r1k1][]=relationship1Value2&key2-form-name=value2&key1-form-name=value1&relationship2-form-name[subKey1]=subValue1");
    #endif
}

- (void)testShouldSerializeToJSON
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
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
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
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
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:@"root"];
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
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:objectMapping objectClass:[NSDictionary class] rootKeyPath:nil];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    // Encodes differently on iOS / OS X
    #if TARGET_OS_IPHONE
    expect(string).to.equal(@"{\"stringTest\":\"The string\",\"hasOne\":{\"date\":\"1970-01-01 00:00:00 +0000\"}}");
    #else
    expect(string).to.equal(@"{\"hasOne\":{\"date\":\"1970-01-01 00:00:00 +0000\"},\"stringTest\":\"The string\"}");
    #endif
}

- (void)testShouldEncloseTheSerializationInAContainerIfRequested
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key1" toKeyPath:@"key1-form-name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"key2" toKeyPath:@"key2-form-name"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:@"stuff"];
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
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:objectMapping objectClass:[NSDictionary class] rootKeyPath:nil];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    expect(string).to.equal(@"{\"hasMany\":[{\"date\":\"1970-01-01 00:00:00 +0000\"}],\"stringTest\":\"The string\"}");
}

- (void)testShouldSerializeAnNSNumberContainingABooleanToTrueFalseIfRequested
{
    NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", [NSNumber numberWithBool:YES], @"boolean", nil];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKAttributeMapping *attributeMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"boolean" toKeyPath:@"boolean-value"];
    [mapping addPropertyMapping:attributeMapping];    
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
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
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    NSData *data = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeJSON error:&error];
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    expect(error).to.beNil();
    expect(string).to.equal(@"{\"key1-form-name\":\"value1\",\"set-form-name\":[\"setElementOne\",\"setElementTwo\",\"setElementThree\"]}");
}

- (void)testParameterizationOfAttributesNestedByKeyPath
{
    NSDictionary *object = @{ @"name" : @"Blake Watters", @"occupation" : @"Hacker" };
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"user.name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"occupation" toKeyPath:@"user.job"]];
    
    NSError *error = nil;
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
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
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[NSDictionary class] rootKeyPath:nil];
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:object requestDescriptor:requestDescriptor error:&error];
    NSDictionary *expected = @{@"user": @{@"anotherKeyPath": @{@"name": @"Blake Watters", @"another": @{ @"job": @"Hacker"}}}};
    expect(parameters).to.equal(expected);
}

@end
