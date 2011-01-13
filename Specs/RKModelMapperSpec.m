//
//  RKObjectMapperSpec.m
//  RestKit
//
//  Created by Jeremy Ellison on 12/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKObjectMapper.h"

#import "RKMappableObject.h"
#import "RKMappableAssociation.h"
#import "RKObjectMapperSpecModel.h"

@interface RKObjectMapperSpec : NSObject <UISpec>

- (NSString*)jsonString;
- (NSString*)jsonCollectionString;

@end

@implementation RKObjectMapperSpec

- (void)itShouldMapFromJSON {
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
	id result = [mapper mapFromString:[self jsonString]];
	
	[expectThat(result) shouldNot:be(nil)];
	[expectThat([result dateTest]) shouldNot:be(nil)];
	[expectThat([result numberTest]) should:be(2)];
	[expectThat([result stringTest]) should:be(@"SomeString")];
	
	[expectThat([result hasOne]) shouldNot:be(nil)];
	[expectThat([[result hasOne] testString]) should:be(@"A String")];
	
	[expectThat([result hasMany]) shouldNot:be(nil)];
	[expectThat([[result hasMany] count]) should:be(2)];
}

- (void)itShouldMapObjectsFromJSON {
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
	NSString* collectionString = [self jsonCollectionString];
	NSArray* results = [mapper mapFromString:collectionString];
	NSLog(@"Results: %@", results);
	[expectThat([results count]) should:be(2)];
	
	RKMappableObject* result = (RKMappableObject*) [results objectAtIndex:0];
	[expectThat(result) shouldNot:be(nil)];
	[expectThat([result dateTest]) shouldNot:be(nil)];
	[expectThat([result numberTest]) should:be(2)];
	[expectThat([result stringTest]) should:be(@"SomeString")];
	
	[expectThat([result hasOne]) shouldNot:be(nil)];
	[expectThat([[result hasOne] testString]) should:be(@"A String")];
	
	[expectThat([result hasMany]) shouldNot:be(nil)];
	[expectThat([[result hasMany] count]) should:be(2)];
}

// TODO: re-implement these specs when we re-implement xml parsing.
//- (void)itShouldMapFromXML {
//	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
//	mapper.format = RKMappingFormatXML;
//	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
//	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
//	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
//	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
//	id result = [mapper mapFromString:[self xmlString]];
//	
//	[expectThat(result) shouldNot:be(nil)];
//	[expectThat([result dateTest]) shouldNot:be(nil)];
//	[expectThat([result numberTest]) should:be(2)];
//	[expectThat([result stringTest]) should:be(@"SomeString")];
//	
//	[expectThat([result hasOne]) shouldNot:be(nil)];
//	[expectThat([[result hasOne] testString]) should:be(@"A String")];
//	
//	[expectThat([result hasMany]) shouldNot:be(nil)];
//	[expectThat([[result hasMany] count]) should:be(2)];
//}
//
//- (void)itShouldMapObjectsFromXML {
//	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
//	mapper.format = RKMappingFormatXML;
//	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
//	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
//	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
//	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
//	NSArray* results = [mapper mapFromString:[self xmlCollectionString]];
//	[expectThat([results count]) should:be(2)];
//	
//	RKMappableObject* result = (RKMappableObject*) [results objectAtIndex:0];
//	[expectThat(result) shouldNot:be(nil)];
//	[expectThat([result dateTest]) shouldNot:be(nil)];
//	[expectThat([result numberTest]) should:be(2)];
//	[expectThat([result stringTest]) should:be(@"SomeString")];
//	
//	[expectThat([result hasOne]) shouldNot:be(nil)];
//	[expectThat([[result hasOne] testString]) should:be(@"A String")];
//	
//	[expectThat([result hasMany]) shouldNot:be(nil)];
//	[expectThat([[result hasMany] count]) should:be(2)];
//}

- (void)itShouldNotUpdateNilPropertyToNil {
	RKObjectMapperSpecModel* model = [[RKObjectMapperSpecModel alloc] autorelease];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	[mapper updateModel:model ifNewPropertyValue:nil forPropertyNamed:@"name"];
	
	[expectThat(model.name) should:be(nil)];
}

- (void)itShouldBeAbleToSetNonNilPropertiesToNil {
	RKObjectMapperSpecModel* model = [[RKObjectMapperSpecModel alloc] autorelease];
	model.age = [NSNumber numberWithInt:0];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	[mapper updateModel:model ifNewPropertyValue:nil forPropertyNamed:@"age"];
	
	[expectThat(model.age) should:be(nil)];
}

- (void)itShouldBeAbleToSetNilPropertiesToNonNil {
	RKObjectMapperSpecModel* model = [[RKObjectMapperSpecModel alloc] autorelease];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	[mapper updateModel:model ifNewPropertyValue:[NSNumber numberWithInt:0] forPropertyNamed:@"age"];
	
	[expectThat(model.age) should:be([NSNumber numberWithInt:0])];
}

- (void)itShouldBeAbleToSetNonNilNSStringPropertiesToNonNil {
	RKObjectMapperSpecModel* model = [[RKObjectMapperSpecModel alloc] autorelease];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	
	model.name = @"Bob";
	[mapper updateModel:model ifNewPropertyValue:@"Will" forPropertyNamed:@"name"];
	[expectThat(model.name) should:be(@"Will")];	
}

- (void)itShouldBeAbleToSetNonNilNSNumberPropertiesToNonNil {
	RKObjectMapperSpecModel* model = [[RKObjectMapperSpecModel alloc] autorelease];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	
	model.age = [NSNumber numberWithInt:16];
	[mapper updateModel:model ifNewPropertyValue:[NSNumber numberWithInt:17] forPropertyNamed:@"age"];
	[expectThat(model.age) should:be([NSNumber numberWithInt:17])];	
}

- (void)itShouldBeAbleToSetNonNilNSDatePropertiesToNonNil {
	RKObjectMapperSpecModel* model = [[RKObjectMapperSpecModel alloc] autorelease];
	RKObjectMapper* mapper = [[RKObjectMapper alloc] init];
	
	model.createdAt = [NSDate date];
	[mapper updateModel:model ifNewPropertyValue:[NSDate dateWithTimeIntervalSince1970:0] forPropertyNamed:@"createdAt"];
	[expectThat(model.createdAt) should:be([NSDate dateWithTimeIntervalSince1970:0])];	
}


@end

@implementation RKObjectMapperSpec (Private)

- (NSString*)jsonString {
	return
	@"{"
	@"   \"test_serialization_class\":{"
	@"      \"date_test\":\"2009-08-17T19:24:40Z\","
	@"      \"number_test\":2,"
	@"      \"string_test\":\"SomeString\","
	@"      \"has_one\":{"
	@"         \"test_string\":\"A String\""
	@"      },"
	@"      \"has_manys\":["
	@"         {"
	@"            \"has_many\":{"
	@"               \"test_string\":\"A String 2\""
	@"            }"
	@"         },"
	@"         {"
	@"            \"has_many\":{"
	@"               \"test_string\":\"A String 3\""
	@"            }"
	@"         }"
	@"      ]"
	@"   }"
	@"}";
}

- (NSString*)jsonCollectionString {
	return
	@"["
	@"      {"
	@"         \"test_serialization_class\":{"
	@"            \"date_test\":\"2009-08-17T19:24:40Z\","
	@"            \"number_test\":2,"
	@"            \"string_test\":\"SomeString\","
	@"            \"has_one\":{"
	@"               \"test_string\":\"A String\""
	@"            },"
	@"            \"has_manys\":["
	@"               {"
	@"                  \"has_many\":{"
	@"                     \"test_string\":\"A String 2\""
	@"                  }"
	@"               },"
	@"               {"
	@"                  \"has_many\":{"
	@"                     \"test_string\":\"A String 3\""
	@"                  }"
	@"               }"
	@"            ]"
	@"         }"
	@"      },"
	@"      {"
	@"         \"test_serialization_class\":{"
	@"            \"date_test\":\"2009-08-17T19:24:40Z\","
	@"            \"number_test\":2,"
	@"            \"string_test\":\"SomeString\","
	@"            \"has_one\":{"
	@"               \"test_string\":\"A String\""
	@"            },"
	@"            \"has_manys\":["
	@"               {"
	@"                  \"has_many\":{"
	@"                     \"test_string\":\"A String 2\""
	@"                  }"
	@"               },"
	@"               {"
	@"                  \"has_many\":{"
	@"                     \"test_string\":\"A String 3\""
	@"                  }"
	@"               }"
	@"            ]"
	@"         }"
	@"      }"
	@"]"
	@"";
}

- (NSString*)xmlString {
	NSString* xml = @"<test_serialization_class>"
	@"<date_test type='datetime'>2009-08-17T19:24:40Z</date_test>"
	@"<number_test type='integer'>2</number_test>"
	@"<string_test>SomeString</string_test>"
	@"<has_one>"
	@"<test_string>A String</test_string>"
	@"</has_one>"
	@"<has_manys>"
	@"<has_many>"
	@"<test_string>A String 2</test_string>"
	@"</has_many>"
	@"<has_many>"
	@"<test_string>A String 3</test_string>"
	@"</has_many>"
	@"</has_manys>"
	@"</test_serialization_class>";
	return xml;
}

- (NSString*)xmlCollectionString {
	NSString* xml = @"<test_serialization_classes>"
	@"<test_serialization_class>"
	@"<date_test type='datetime'>2009-08-17T19:24:40Z</date_test>"
	@"<number_test type='integer'>2</number_test>"
	@"<string_test>SomeString</string_test>"
	@"<has_one>"
	@"<test_string>A String</test_string>"
	@"</has_one>"
	@"<has_manys>"
	@"<has_many>"
	@"<test_string>A String 2</test_string>"
	@"</has_many>"
	@"<has_many>"
	@"<test_string>A String 3</test_string>"
	@"</has_many>"
	@"</has_manys>"
	@"</test_serialization_class>"
	@"<test_serialization_class>"
	@"<date_test type='datetime'>2009-08-17T19:24:40Z</date_test>"
	@"<number_test type='integer'>2</number_test>"
	@"<string_test>SomeString</string_test>"
	@"<has_one>"
	@"<test_string>A String</test_string>"
	@"</has_one>"
	@"<has_manys>"
	@"<has_many>"
	@"<test_string>A String 2</test_string>"
	@"</has_many>"
	@"<has_many>"
	@"<test_string>A String 3</test_string>"
	@"</has_many>"
	@"</has_manys>"
	@"</test_serialization_class>"
	@"</test_serialization_classes>";
	return xml;
}

@end
