//
//  RKXMLParserTest.m
//  RestKit
//
//  Created by Jeremy Ellison on 3/29/11.
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
#import "RKXMLParserXMLReader.h"

// See Tests/Fixtures/XML/tab_data.xml
@interface RKTestTabData : NSObject {
    NSString *_title;
    NSString *_summary;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *summary;

@end

@implementation RKTestTabData

@synthesize title = _title;
@synthesize summary = _summary;

@end

@interface RKXMLParserTest : RKTestCase {

}

@end

@implementation RKXMLParserTest

- (void)testShouldMapASingleXMLObjectPayloadToADictionary
{
    NSString *data = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  <float type=\"float\">2.4</float>\n  <string>string</string>\n  <number type=\"integer\">1</number>\n</hash>\n";
    NSError *error = [[NSError alloc] init];
    RKXMLParserXMLReader *parser = [[RKXMLParserXMLReader new] autorelease];
    id result = [parser objectFromString:data error:&error];
    assertThat(NSStringFromClass([result class]), is(equalTo(@"__NSCFDictionary")));
    assertThatFloat([[[result valueForKeyPath:@"hash.float"] valueForKey:@"text"] floatValue], is(equalToFloat(2.4f)));
    assertThatInt([[[result valueForKeyPath:@"hash.number"] valueForKey:@"text"] intValue], is(equalToInt(1)));
    assertThat([result valueForKeyPath:@"hash.string"], is(equalTo(@"string")));
}

- (void)testShouldMapMultipleObjectsToAnArray
{
    NSString *data = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records type=\"array\">\n  <record>\n    <float type=\"float\">2.4</float>\n    <string>string</string>\n    <number type=\"integer\">1</number>\n  </record>\n  <record>\n    <another-number type=\"integer\">1</another-number>\n  </record>\n</records>\n";
    NSError *error = [[NSError alloc] init];
    RKXMLParserXMLReader *parser = [[RKXMLParserXMLReader new] autorelease];
    id result = [parser objectFromString:data error:&error];
    NSArray *records = (NSArray *)[result valueForKeyPath:@"records.record"];
    assertThatUnsignedInteger([records count], is(equalToInt(2)));
    id result1 = [records objectAtIndex:0];
    assertThat(NSStringFromClass([result1 class]), is(equalTo(@"__NSCFDictionary")));
    assertThatFloat([[[result1 valueForKeyPath:@"float"] valueForKey:@"text"] floatValue], is(equalToFloat(2.4f)));
    assertThatInt([[[result1 valueForKeyPath:@"number"] valueForKey:@"text"] intValue], is(equalToInt(1)));
    assertThat([result1 valueForKeyPath:@"string"], is(equalTo(@"string")));
    id result2 = [records objectAtIndex:1];
    assertThatInt([[[result2 valueForKeyPath:@"another-number"] valueForKey:@"text"] intValue], is(equalToInt(1)));
}

- (void)testShouldMapXML
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestTabData class]];
    [mapping mapAttributes:@"title", @"summary", nil];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider alloc] init];
    id data = [RKTestFixture parsedObjectWithContentsOfFixture:@"tab_data.xml"];
    assertThat([data valueForKeyPath:@"tabdata.item"], is(instanceOf([NSArray class])));
    [provider setMapping:mapping forKeyPath:@"tabdata.item"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:data mappingProvider:provider];
    RKObjectMappingResult *result = [mapper performMapping];
    assertThatUnsignedInteger([[result asCollection] count], is(equalToInt(2)));
    assertThatUnsignedInteger([[data valueForKeyPath:@"tabdata.title"] count], is(equalToInt(2)));
    assertThatUnsignedInteger([[data valueForKeyPath:@"tabdata.item"] count], is(equalToInt(2)));
}

- (void)testShouldParseXMLWithAttributes
{
    NSString *XML = [RKTestFixture stringWithContentsOfFixture:@"container_attributes.xml"];
    NSError *error = [[NSError alloc] init];
    RKXMLParserXMLReader *parser = [[RKXMLParserXMLReader new] autorelease];
    NSDictionary *result = [parser objectFromString:XML error:&error];
    assertThat(result, is(instanceOf([NSDictionary class])));
    NSArray *elements = [[result objectForKey:@"elements"] objectForKey:@"element"];
    assertThat(elements, isNot(nilValue()));
    assertThat(elements, is(instanceOf([NSArray class])));
    assertThat(elements, hasCountOf(2));
    NSDictionary *firstElement = [elements objectAtIndex:0];
    assertThat([firstElement objectForKey:@"attribute"], is(equalTo(@"1")));
    assertThat([firstElement objectForKey:@"subelement"], is(equalTo(@"text")));
    NSDictionary *secondElement = [elements objectAtIndex:1];
    assertThat([secondElement objectForKey:@"attribute"], is(equalTo(@"2")));
    assertThat([secondElement objectForKey:@"subelement"], is(equalTo(@"text2")));
}

- (void)testShouldParseXMLWithAttributesInTextNodes
{
    NSString *XML = [RKTestFixture stringWithContentsOfFixture:@"attributes_without_text_content.xml"];
    NSError *error = [[NSError alloc] init];
    RKXMLParserXMLReader *parser = [[RKXMLParserXMLReader new] autorelease];
    NSDictionary *result = [parser objectFromString:XML error:&error];
    NSDictionary *exchangeRate = [result objectForKey:@"exchange_rate"];
    assertThat(exchangeRate, is(notNilValue()));
    assertThat([exchangeRate objectForKey:@"type"], is(equalTo(@"XML_RATE_TYPE_EBNK_MIDDLE")));
    assertThat([exchangeRate objectForKey:@"valid_from"], is(equalTo(@"2011-08-03 00:00:00.0")));
    assertThat([exchangeRate objectForKey:@"name"], nilValue()); // This is to test for bug in parsing
    NSArray *currency = [exchangeRate objectForKey:@"currency"];
    assertThat(currency, hasCountOf(3));
    NSDictionary *firstCurrency = [currency objectAtIndex:0];
    assertThat(firstCurrency, is(instanceOf([NSDictionary class])));
    assertThat([firstCurrency objectForKey:@"name"], is(equalTo(@"AUD")));
    assertThat([firstCurrency objectForKey:@"quota"], is(equalTo(@"1")));
    assertThat([firstCurrency objectForKey:@"rate"], is(equalTo(@"18.416")));

    NSDictionary *secondCurrency = [currency objectAtIndex:1];
    assertThat(secondCurrency, is(instanceOf([NSDictionary class])));
    assertThat([secondCurrency objectForKey:@"name"], is(equalTo(@"HRK")));
    assertThat([secondCurrency objectForKey:@"quota"], is(equalTo(@"1")));
    assertThat([secondCurrency objectForKey:@"rate"], is(equalTo(@"3.25017")));

    NSDictionary *thirdCurrency = [currency objectAtIndex:2];
    assertThat(thirdCurrency, is(instanceOf([NSDictionary class])));
    assertThat([thirdCurrency objectForKey:@"name"], is(equalTo(@"DKK")));
    assertThat([thirdCurrency objectForKey:@"quota"], is(equalTo(@"1")));
    assertThat([thirdCurrency objectForKey:@"rate"], is(equalTo(@"3.251")));
}

- (void)testShouldNotCrashWhileParsingOrdersXML
{
    NSString *XML = [RKTestFixture stringWithContentsOfFixture:@"orders.xml"];
    NSError *error = [[NSError alloc] init];
    RKXMLParserXMLReader *parser = [[RKXMLParserXMLReader new] autorelease];
    NSException *exception = nil;
    @try {
        [parser objectFromString:XML error:&error];;
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(nilValue()));
    }
}

- (void)testShouldParseXMLWithCDATA
{
    NSString *XML = [RKTestFixture stringWithContentsOfFixture:@"zend.xml"];
    NSError *error = [[NSError alloc] init];
    RKXMLParserXMLReader *parser = [[RKXMLParserXMLReader new] autorelease];
    NSDictionary *output = [parser objectFromString:XML error:&error];
    NSArray *map = [output valueForKeyPath:@"Api.getList.map"];
    assertThat(map, isNot(nilValue()));
    assertThat(map, hasCountOf(4));
    assertThat([[map objectAtIndex:0] valueForKey:@"title"], is(equalTo(@"Main World Map")));
    assertThat([[map objectAtIndex:1] valueForKey:@"title"], is(equalTo(@"Section Map: Narshe Village")));
    assertThat([[map objectAtIndex:2] valueForKey:@"subtitle"], is(equalTo(@"Kary lives here.")));
}

- (void)testShouldConsiderASingleCloseTagAnEmptyContainer
{
    NSString *XML = @"<users />";
    NSError *error = [[NSError alloc] init];
    RKXMLParserXMLReader *parser = [[RKXMLParserXMLReader new] autorelease];
    NSDictionary *output = [parser objectFromString:XML error:&error];
    NSDictionary *users = [output valueForKey:@"users"];
    NSLog(@"%@", output);
    assertThat(users, is(notNilValue()));
    assertThatBool([users isKindOfClass:[NSDictionary class]], is(equalToBool(YES)));
}

- (void)testShouldParseRelativelyComplexXML
{
    NSString *XML = [RKTestFixture stringWithContentsOfFixture:@"national_weather_service.xml"];
    NSError *error = [[NSError alloc] init];
    RKXMLParserXMLReader *parser = [[RKXMLParserXMLReader new] autorelease];
    NSException *exception = nil;
    @try {
        [parser objectFromString:XML error:&error];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(nilValue()));
    }
}

- (void)testShouldParseXMLElementsAndAttributesProperly
{

    NSString *XML = [RKTestFixture stringWithContentsOfFixture:@"channels.xml"];
    NSError *error = [[NSError alloc] init];
    RKXMLParserXMLReader *parser = [[RKXMLParserXMLReader new] autorelease];
    NSDictionary *result = [parser objectFromString:XML error:&error];

    NSLog(@"result : %@", result);

    NSDictionary *channel = [[result objectForKey:@"Channels"] objectForKey:@"Channel"];
    assertThat(channel, is(notNilValue()));

    // Check to see if the Channel attributes are properly parsed
    assertThat([channel objectForKey:@"Identifier"], is(equalTo(@"1172")));
    assertThat([channel objectForKey:@"Title"], is(equalTo(@"MySpecialTitle")));
    assertThat([channel objectForKey:@"Position"], is(equalTo(@"2234")));

    NSLog(@"channel: %@", channel);

    // Check to see if the Channel elements are properly parsed
    assertThat([channel objectForKey:@"Languages"], is(equalTo(@"it")));

    assertThat([[channel objectForKey:@"Stream"] objectForKey:@"text"], is(equalTo(@"MySpecialTitle")));
    assertThat([[channel objectForKey:@"Stream"] objectForKey:@"Identifier"], is(equalTo(@"MySpecialTitle")));
    assertThat([[channel objectForKey:@"Stream"] objectForKey:@"Index"], is(equalTo(@"0")));

    assertThat([[[channel objectForKey:@"Program"] objectAtIndex:0] objectForKey:@"Identifier"], is(equalTo(@"42883461")));
    assertThat([[[channel objectForKey:@"Program"] objectAtIndex:0] objectForKey:@"Start"], is(equalTo(@"2011-12-19 20:00:00Z")));
    assertThat([[[channel objectForKey:@"Program"] objectAtIndex:0] objectForKey:@"End"], is(equalTo(@"2011-12-19 21:00:00Z")));
    assertThat([[[channel objectForKey:@"Program"] objectAtIndex:0] objectForKey:@"Title"], is(equalTo(@"Program Title 1")));

    assertThat([[[channel objectForKey:@"Program"] objectAtIndex:1] objectForKey:@"Identifier"], is(equalTo(@"42883471")));
    assertThat([[[channel objectForKey:@"Program"] objectAtIndex:1] objectForKey:@"Start"], is(equalTo(@"2011-12-19 21:00:00Z")));
    assertThat([[[channel objectForKey:@"Program"] objectAtIndex:1] objectForKey:@"End"], is(equalTo(@"2011-12-19 23:00:00Z")));
    assertThat([[[channel objectForKey:@"Program"] objectAtIndex:1] objectForKey:@"Title"], is(equalTo(@"Program Title")));

    assertThat([[channel objectForKey:@"Image"] objectAtIndex:0], is(equalTo(@"http://domain.com/Images/MySpecialTitle.png")));
    assertThat([[[channel objectForKey:@"Image"] objectAtIndex:1] objectForKey:@"text"], is(equalTo(@"http://domain.com/Images/65x35/2234.png")));
    assertThat([[[channel objectForKey:@"Image"] objectAtIndex:1] objectForKey:@"Width"], is(equalTo(@"65")));
    assertThat([[[channel objectForKey:@"Image"] objectAtIndex:1] objectForKey:@"Height"], is(equalTo(@"35")));
}

@end
