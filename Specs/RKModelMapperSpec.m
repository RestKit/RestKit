//
//  RKResourceMapperSpec.m
//  RestKit
//
//  Created by Jeremy Ellison on 12/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKResourceMapper.h"

#import "RKMappableObject.h"
#import "RKMappableAssociation.h"
#import "RKResourceMapperSpecModel.h"

@interface RKResourceMapperSpec : NSObject <UISpec>

@end

@implementation RKResourceMapperSpec

- (void)itShouldMapFromJSON {
	RKResourceMapper* mapper = [[RKResourceMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
	id result = [mapper buildModelFromString:[self jsonString]];
	
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
	RKResourceMapper* mapper = [[RKResourceMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
	NSArray* results = [mapper buildModelsFromString:[self jsonCollectionString]];
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

- (void)itShouldMapFromXML {
	RKResourceMapper* mapper = [[RKResourceMapper alloc] init];
	mapper.format = RKMappingFormatXML;
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
	id result = [mapper buildModelFromString:[self xmlString]];
	
	[expectThat(result) shouldNot:be(nil)];
	[expectThat([result dateTest]) shouldNot:be(nil)];
	[expectThat([result numberTest]) should:be(2)];
	[expectThat([result stringTest]) should:be(@"SomeString")];
	
	[expectThat([result hasOne]) shouldNot:be(nil)];
	[expectThat([[result hasOne] testString]) should:be(@"A String")];
	
	[expectThat([result hasMany]) shouldNot:be(nil)];
	[expectThat([[result hasMany] count]) should:be(2)];
}

- (void)itShouldMapObjectsFromXML {
	RKResourceMapper* mapper = [[RKResourceMapper alloc] init];
	mapper.format = RKMappingFormatXML;
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerClass:[RKMappableAssociation class] forElementNamed:@"has_one"];
	NSArray* results = [mapper buildModelsFromString:[self xmlCollectionString]];
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

- (void)itShouldNotUpdateNilPropertyToNil {
	RKResourceMapperSpecModel* model = [[RKResourceMapperSpecModel alloc] autorelease];
	RKResourceMapper* mapper = [[RKResourceMapper alloc] init];
	[mapper updateObject:model ifNewPropertyValue:nil forPropertyNamed:@"name"];
	
	[expectThat(model.name) should:be(nil)];
}

- (void)itShouldBeAbleToSetNonNilPropertiesToNil {
	RKResourceMapperSpecModel* model = [[RKResourceMapperSpecModel alloc] autorelease];
	model.age = [NSNumber numberWithInt:0];
	RKResourceMapper* mapper = [[RKResourceMapper alloc] init];
	[mapper updateObject:model ifNewPropertyValue:nil forPropertyNamed:@"age"];
	
	[expectThat(model.age) should:be(nil)];
}

- (void)itShouldBeAbleToSetNilPropertiesToNonNil {
	RKResourceMapperSpecModel* model = [[RKResourceMapperSpecModel alloc] autorelease];
	RKResourceMapper* mapper = [[RKResourceMapper alloc] init];
	[mapper updateObject:model ifNewPropertyValue:[NSNumber numberWithInt:0] forPropertyNamed:@"age"];
	
	[expectThat(model.age) should:be([NSNumber numberWithInt:0])];
}

- (void)itShouldBeAbleToSetNonNilNSStringPropertiesToNonNil {
	RKResourceMapperSpecModel* model = [[RKResourceMapperSpecModel alloc] autorelease];
	RKResourceMapper* mapper = [[RKResourceMapper alloc] init];
	
	model.name = @"Bob";
	[mapper updateObject:model ifNewPropertyValue:@"Will" forPropertyNamed:@"name"];
	[expectThat(model.name) should:be(@"Will")];	
}

- (void)itShouldBeAbleToSetNonNilNSNumberPropertiesToNonNil {
	RKResourceMapperSpecModel* model = [[RKResourceMapperSpecModel alloc] autorelease];
	RKResourceMapper* mapper = [[RKResourceMapper alloc] init];
	
	model.age = [NSNumber numberWithInt:16];
	[mapper updateObject:model ifNewPropertyValue:[NSNumber numberWithInt:17] forPropertyNamed:@"age"];
	[expectThat(model.age) should:be([NSNumber numberWithInt:17])];	
}

- (void)itShouldBeAbleToSetNonNilNSDatePropertiesToNonNil {
	RKResourceMapperSpecModel* model = [[RKResourceMapperSpecModel alloc] autorelease];
	RKResourceMapper* mapper = [[RKResourceMapper alloc] init];
	
	model.createdAt = [NSDate date];
	[mapper updateObject:model ifNewPropertyValue:[NSDate dateWithTimeIntervalSince1970:0] forPropertyNamed:@"createdAt"];
	[expectThat(model.createdAt) should:be([NSDate dateWithTimeIntervalSince1970:0])];	
}


@end

@implementation RKResourceMapperSpec (Private)

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
	@"{"
	@"   \"test_serialization_classes\":["
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
	@"   ]"
	@"}";
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
