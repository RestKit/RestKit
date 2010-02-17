//
//  CRTransactionSpec.m
//  Cash Register
//
//  Created by Jeremy Ellison on 12/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//


#import "UISpec.h"
#import "dsl/UIExpectation.h"

#import "RKModelMapper.h"

#import "RKMappableObject.h"
#import "RKMappableAssociation.h"

@interface RKModelMapperSpec : NSObject <UISpec>

@end

@implementation RKModelMapperSpec

- (void)itShouldKnowIfASelectorIsAParentSelector {
	RKModelMapper* mapper = [[RKModelMapper alloc] init];
	[expectThat((BOOL)[mapper isParentSelector:@"blah > blah"]) should:be(YES)];
	[expectThat((BOOL)[mapper isParentSelector:@"blah"]) should:be(NO)];
	[mapper release];
}

- (void)itShouldKnowTheContainingElementNameForASelector {
	RKModelMapper* mapper = [[RKModelMapper alloc] init];
	[expectThat([mapper containingElementNameForSelector:@"blahs > blah"]) should:be(@"blahs")];
	[mapper release];
}

- (void)itShouldKnowTheChildElementNameForASelector {
	RKModelMapper* mapper = [[RKModelMapper alloc] init];
	[expectThat([mapper childElementNameForSelelctor:@"blahs > blah"]) should:be(@"blah")];
	[mapper release];
}

- (void)itShouldMapFromJSON {
	RKModelMapper* mapper = [[RKModelMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
	[mapper registerModel:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerModel:[RKMappableAssociation class] forElementNamed:@"has_one"];
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
	RKModelMapper* mapper = [[RKModelMapper alloc] init];
	mapper.format = RKMappingFormatJSON;
	[mapper registerModel:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerModel:[RKMappableAssociation class] forElementNamed:@"has_one"];
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
	RKModelMapper* mapper = [[RKModelMapper alloc] init];
	mapper.format = RKMappingFormatXML;
	[mapper registerModel:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerModel:[RKMappableAssociation class] forElementNamed:@"has_one"];
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
	RKModelMapper* mapper = [[RKModelMapper alloc] init];
	mapper.format = RKMappingFormatXML;
	[mapper registerModel:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[RKMappableObject class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[RKMappableAssociation class] forElementNamed:@"has_many"];
	[mapper registerModel:[RKMappableAssociation class] forElementNamed:@"has_one"];
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

@end

@implementation RKModelMapperSpec (Private)

- (NSString*)jsonString {
	NSString* json = @"{\"test_serialization_class\": "
	@"{\"date_test\": \"2009-08-17T19:24:40Z\", "
	@"\"number_test\": 2, "
	@"\"string_test\": \"SomeString\", "
	@"\"has_one\": {\"test_string\": \"A String\"}, "
	@"\"has_manys\": [{\"test_string\": \"A String 2\"}, "
	@"{\"test_string\": \"A String 3\"}]"
	@"}}";
	return json;
}

- (NSString*)jsonCollectionString {
	NSString* json = @"["
	@"{\"test_serialization_class\": "
	@"{\"date_test\": \"2009-08-17T19:24:40Z\", "
	@"\"number_test\": 2, "
	@"\"string_test\": \"SomeString\", "
	@"\"has_one\": {\"test_string\": \"A String\"}, "
	@"\"has_manys\": [{\"test_string\": \"A String 2\"}, "
	@"{\"test_string\": \"A String 3\"}]"
	@"}"
	@"}, "
	@"{\"test_serialization_class\": "
	@"{\"date_test\": \"2009-08-17T19:24:40Z\", "
	@"\"number_test\": 2, "
	@"\"string_test\": \"SomeString\", "
	@"\"has_one\": {\"test_string\": \"A String\"}, "
	@"\"has_manys\": [{\"test_string\": \"A String 2\"}, "
	@"{\"test_string\": \"A String 3\"}]"
	@"}"
	@"}"
	@"]";
	return json;
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
