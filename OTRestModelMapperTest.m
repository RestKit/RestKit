//
//  OTRestModelMapperTest.m
//  OTRestFramework
//
//  Created by Jeremy Ellison on 8/17/09.
//  Copyright 2009 Objective3. All rights reserved.
//

#import "OTRestModelMapperTest.h"
#import "OTRestModelMapper.h"
// Because we are going to test private methods
#import "OTRestModelMapper_Private.h"
#import "TestSerialization.h"

@interface OTRestModelMapperTest (Private)

- (NSString*)jsonString;
- (NSString*)jsonCollectionString;

- (NSString*)xmlString;
- (NSString*)xmlCollectionString;

@end


@implementation OTRestModelMapperTest

- (void)testIsParentSelector {
	OTRestModelMapper* mapper = [[OTRestModelMapper alloc] init];
	
	STAssertTrue([mapper isParentSelector:@"blah > blah"], nil);
	STAssertFalse([mapper isParentSelector:@"blah"], nil);
	[mapper release];
}

- (void)testContainingElementNameForSelector {
	OTRestModelMapper* mapper = [[OTRestModelMapper alloc] init];
	STAssertTrue([[mapper containingElementNameForSelector:@"blahs > blah"] isEqualToString:@"blahs"], nil);
	[mapper release];
}

- (void)testChildElementNameForSelector {
	OTRestModelMapper* mapper = [[OTRestModelMapper alloc] init];
	STAssertTrue([[mapper childElementNameForSelelctor:@"blahs > blah"] isEqualToString:@"blah"], nil);
	[mapper release];
}

- (void)testJSONMapping {
	OTRestModelMapper* mapper = [[OTRestModelMapper alloc] initWithParsingStyle:OTRestParsingStyleJSON];
	[mapper registerModel:[TestSerialization class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[TestSerialization class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[TestSerializationAssociation class] forElementNamed:@"has_many"];
	[mapper registerModel:[TestSerializationAssociation class] forElementNamed:@"has_one"];
	id result = [mapper buildModelFromString:[self jsonString]];
	
	STAssertNotNil(result, @"Result should not be nil, %@, mapper: %@, jsonstr: %@", result, mapper, [self jsonString]);
	STAssertNotNil([result dateTest], @"dateTest should not be nil");
	STAssertTrue([[result numberTest] isEqualToNumber:[NSNumber numberWithInt:2]], @"numberTest should be 2");
	STAssertTrue([[result stringTest] isEqualToString:@"SomeString"], @"stringTest should == SomeString, is %@", [result stringTest]);
	
	STAssertNotNil([result hasOne], @"has one association should not be nil");
	STAssertTrue([[[result hasOne] testString] isEqualToString:@"A String"], @"has one association (%@) stringTest should be 'A String', is %@", [result hasOne], [[result hasOne] testString]);
	
	STAssertNotNil([result hasMany], @"has many association should not be nil");
	STAssertTrue([[result hasMany] count] == 2, @"there should be 2 has many associations");
}

- (void)testJSONCollectionMapping {
	OTRestModelMapper* mapper = [[OTRestModelMapper alloc] initWithParsingStyle:OTRestParsingStyleJSON];
	[mapper registerModel:[TestSerialization class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[TestSerialization class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[TestSerializationAssociation class] forElementNamed:@"has_many"];
	[mapper registerModel:[TestSerializationAssociation class] forElementNamed:@"has_one"];
	NSArray* results = [mapper buildModelsFromString:[self jsonCollectionString]];
	for(TestSerialization* result in results) {
		STAssertNotNil(result, @"Result should not be nil, %@, mapper: %@, jsonstr: %@", result, mapper, [self jsonString]);
		STAssertNotNil([result dateTest], @"dateTest should not be nil");
		STAssertTrue([[result numberTest] isEqualToNumber:[NSNumber numberWithInt:2]], @"numberTest should be 2");
		STAssertTrue([[result stringTest] isEqualToString:@"SomeString"], @"stringTest should == SomeString, is %@", [result stringTest]);
		
		STAssertNotNil([result hasOne], @"has one association should not be nil");
		STAssertTrue([[[result hasOne] testString] isEqualToString:@"A String"], @"has one association (%@) stringTest should be 'A String', is %@", [result hasOne], [[result hasOne] testString]);
		
		STAssertNotNil([result hasMany], @"has many association should not be nil");
		STAssertTrue([[result hasMany] count] == 2, @"there should be 2 has many associations");
	}
}

- (void)testXMLMapping {
	OTRestModelMapper* mapper = [[OTRestModelMapper alloc] initWithParsingStyle:OTRestParsingStyleXML];
	[mapper registerModel:[TestSerialization class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[TestSerializationAssociation class] forElementNamed:@"has_many"];
	[mapper registerModel:[TestSerializationAssociation class] forElementNamed:@"has_one"];
	TestSerialization* result = [mapper buildModelFromString:[self xmlString]];
	STAssertNotNil(result, @"Result should not be nil");
	STAssertNotNil([result dateTest], @"dateTest should not be nil");
	STAssertTrue([[result numberTest] isEqualToNumber:[NSNumber numberWithInt:2]], @"numberTest should be 2");
	STAssertTrue([[result stringTest] isEqualToString:@"SomeString"], @"stringTest should == SomeString, is %@", [result stringTest]);
	
	STAssertNotNil([result hasOne], @"has one association should not be nil");
	STAssertTrue([[[result hasOne] testString] isEqualToString:@"A String"], @"has one association (%@) stringTest should be 'A String', is %@", [result hasOne], [[result hasOne] testString]);
	
	STAssertNotNil([result hasMany], @"has many association should not be nil");
	STAssertTrue([[result hasMany] count] == 2, @"there should be 2 has many associations");
	// TODO: test values of testString properties here
}

- (void)testXMLCollectionMapping {
	OTRestModelMapper* mapper = [[OTRestModelMapper alloc] initWithParsingStyle:OTRestParsingStyleXML];
	[mapper registerModel:[TestSerialization class] forElementNamed:@"test_serialization_class"];
	[mapper registerModel:[TestSerializationAssociation class] forElementNamed:@"has_many"];
	[mapper registerModel:[TestSerializationAssociation class] forElementNamed:@"has_one"];
	NSArray* results = [mapper buildModelsFromString:[self xmlCollectionString]];
	for (TestSerialization* result in results) {
		STAssertNotNil(result, @"Result should not be nil");
		STAssertNotNil([result dateTest], @"dateTest should not be nil");
		STAssertTrue([[result numberTest] isEqualToNumber:[NSNumber numberWithInt:2]], @"numberTest should be 2");
		STAssertTrue([[result stringTest] isEqualToString:@"SomeString"], @"stringTest should == SomeString, is %@", [result stringTest]);
		
		STAssertNotNil([result hasOne], @"has one association should not be nil");
		STAssertTrue([[[result hasOne] testString] isEqualToString:@"A String"], @"has one association (%@) stringTest should be 'A String', is %@", [result hasOne], [[result hasOne] testString]);
		
		STAssertNotNil([result hasMany], @"has many association should not be nil");
		STAssertTrue([[result hasMany] count] == 2, @"there should be 2 has many associations");
		// TODO: test values of testString properties here
	}
}

@end

@implementation OTRestModelMapperTest (Private)

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