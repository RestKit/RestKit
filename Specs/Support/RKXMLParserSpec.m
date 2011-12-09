//
//  RKXMLParserLibXMLSpec.m
//  RestKit
//
//  Created by Jeremy Ellison on 3/29/11.
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
#import "RKXMLParserLibXML.h"

// See Specs/Fixtures/XML/tab_data.xml
@interface RKSpecTabData : NSObject {
    NSString* _title;
    NSString* _summary;
}

@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* summary;

@end

@implementation RKSpecTabData

@synthesize title = _title;
@synthesize summary = _summary;

@end

@interface RKXMLParserLibXMLSpec : RKSpec {
    
}

@end

@implementation RKXMLParserLibXMLSpec

- (void)testShouldMapASingleXMLObjectPayloadToADictionary {
    NSString* data = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  <float type=\"float\">2.4</float>\n  <string>string</string>\n  <number type=\"integer\">1</number>\n</hash>\n";
    RKXMLParserLibXML* parser = [[RKXMLParserLibXML new] autorelease];
    id result = [parser parseXML:data];
    assertThat(NSStringFromClass([result class]), is(equalTo(@"__NSCFDictionary")));
    assertThatFloat([[result valueForKeyPath:@"hash.float"] floatValue], is(equalToFloat(2.4f)));
    assertThatInt([[result valueForKeyPath:@"hash.number"] intValue], is(equalToInt(1)));
    assertThat([result valueForKeyPath:@"hash.string"], is(equalTo(@"string")));
}

- (void)testShouldMapMultipleObjectsToAnArray {
    NSString* data = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records type=\"array\">\n  <record>\n    <float type=\"float\">2.4</float>\n    <string>string</string>\n    <number type=\"integer\">1</number>\n  </record>\n  <record>\n    <another-number type=\"integer\">1</another-number>\n  </record>\n</records>\n";
    RKXMLParserLibXML* parser = [[RKXMLParserLibXML new] autorelease];
    id result = [parser parseXML:data];
    NSArray* records = (NSArray*)[result valueForKeyPath:@"records.record"];
    assertThatUnsignedInteger([records count], is(equalToInt(2)));
    id result1 = [records objectAtIndex:0];
    assertThat(NSStringFromClass([result1 class]), is(equalTo(@"__NSCFDictionary")));
    assertThatFloat([[result1 valueForKeyPath:@"float"] floatValue], is(equalToFloat(2.4f)));
    assertThatInt([[result1 valueForKeyPath:@"number"] intValue], is(equalToInt(1)));
    assertThat([result1 valueForKeyPath:@"string"], is(equalTo(@"string")));
    id result2 = [records objectAtIndex:1];
    assertThatInt([[result2 valueForKeyPath:@"another-number"] intValue], is(equalToInt(1)));
}

- (void)testShouldMapXML {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKSpecTabData class]];
    [mapping mapAttributes:@"title", @"summary", nil];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider alloc] init];
    id data = RKSpecParseFixture(@"tab_data.xml");
    assertThat([data valueForKeyPath:@"tabdata.item"], is(instanceOf([NSArray class])));
    [provider setMapping:mapping forKeyPath:@"tabdata.item"];
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:data mappingProvider:provider];
    RKObjectMappingResult* result = [mapper performMapping];
    assertThatUnsignedInteger([[result asCollection] count], is(equalToInt(2)));
    assertThatUnsignedInteger([[data valueForKeyPath:@"tabdata.title"] count], is(equalToInt(2)));
    assertThatUnsignedInteger([[data valueForKeyPath:@"tabdata.item"] count], is(equalToInt(2)));
}

- (void)testShouldParseXMLWithAttributes {
    NSString* XML = RKSpecReadFixture(@"container_attributes.xml");
    RKXMLParserLibXML* parser = [[RKXMLParserLibXML new] autorelease];
    NSDictionary* result = [parser parseXML:XML];
    assertThat(result, is(instanceOf([NSDictionary class])));
    NSArray* elements = [[result objectForKey:@"elements"] objectForKey:@"element"];
    assertThat(elements, isNot(nilValue()));
    assertThat(elements, is(instanceOf([NSArray class])));
    assertThat(elements, hasCountOf(2));
    NSDictionary* firstElement = [elements objectAtIndex:0];
    assertThat([firstElement objectForKey:@"attribute"], is(equalTo(@"1")));
    assertThat([firstElement objectForKey:@"subelement"], is(equalTo(@"text")));
    NSDictionary* secondElement = [elements objectAtIndex:1];
    assertThat([secondElement objectForKey:@"attribute"], is(equalTo(@"2")));
    assertThat([secondElement objectForKey:@"subelement"], is(equalTo(@"text2")));
}

- (void)testShouldParseXMLWithAttributesInTextNodes {
    NSString* XML = RKSpecReadFixture(@"attributes_without_text_content.xml");
    RKXMLParserLibXML* parser = [[RKXMLParserLibXML new] autorelease];
    NSDictionary* result = [parser parseXML:XML];
    NSDictionary* exchangeRate = [result objectForKey:@"exchange_rate"];
    assertThat(exchangeRate, is(notNilValue()));
    assertThat([exchangeRate objectForKey:@"type"], is(equalTo(@"XML_RATE_TYPE_EBNK_MIDDLE")));
    assertThat([exchangeRate objectForKey:@"valid_from"], is(equalTo(@"2011-08-03 00:00:00.0")));    
    NSArray* currency = [exchangeRate objectForKey:@"currency"];
    assertThat(currency, hasCountOf(3));
    NSDictionary* firstCurrency = [currency objectAtIndex:0];
    assertThat(firstCurrency, is(instanceOf([NSDictionary class])));
    assertThat([firstCurrency objectForKey:@"name"], is(equalTo(@"AUD")));
    assertThat([firstCurrency objectForKey:@"quota"], is(equalTo(@"1")));
    assertThat([firstCurrency objectForKey:@"rate"], is(equalTo(@"18.416")));
    
    NSDictionary* secondCurrency = [currency objectAtIndex:1];
    assertThat(secondCurrency, is(instanceOf([NSDictionary class])));
    assertThat([secondCurrency objectForKey:@"name"], is(equalTo(@"HRK")));
    assertThat([secondCurrency objectForKey:@"quota"], is(equalTo(@"1")));
    assertThat([secondCurrency objectForKey:@"rate"], is(equalTo(@"3.25017")));
    
    NSDictionary* thirdCurrency = [currency objectAtIndex:2];
    assertThat(thirdCurrency, is(instanceOf([NSDictionary class])));
    assertThat([thirdCurrency objectForKey:@"name"], is(equalTo(@"DKK")));
    assertThat([thirdCurrency objectForKey:@"quota"], is(equalTo(@"1")));
    assertThat([thirdCurrency objectForKey:@"rate"], is(equalTo(@"3.251")));
}

- (void)testShouldNotCrashWhileParsingOrdersXML {
    NSString *XML = RKSpecReadFixture(@"orders.xml");
    RKXMLParserLibXML* parser = [[RKXMLParserLibXML new] autorelease];
    NSException *exception = nil;
    @try {
        [parser parseXML:XML];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(nilValue()));
    }
}

- (void)testShouldParseXMLWithCDATA {
    NSString *XML = RKSpecReadFixture(@"zend.xml");
    RKXMLParserLibXML* parser = [[RKXMLParserLibXML new] autorelease];
    NSDictionary *output = [parser parseXML:XML];
    NSArray *map = [output valueForKeyPath:@"Api.getList.map"];
    assertThat(map, isNot(nilValue()));
    assertThat(map, hasCountOf(4));
    assertThat([[map objectAtIndex:0] valueForKey:@"title"], is(equalTo(@"Main World Map")));
    assertThat([[map objectAtIndex:1] valueForKey:@"title"], is(equalTo(@"Section Map: Narshe Village")));
    assertThat([[map objectAtIndex:2] valueForKey:@"subtitle"], is(equalTo(@"Kary lives here.")));
}

- (void)testShouldConsiderASingleCloseTagAnEmptyContainer {
    NSString *XML = @"<users />";
    RKXMLParserLibXML* parser = [[RKXMLParserLibXML new] autorelease];
    NSDictionary *output = [parser parseXML:XML];
    NSDictionary *users = [output valueForKey:@"users"];
    assertThat(users, is(notNilValue()));
    assertThatBool([users isKindOfClass:[NSDictionary class]], is(equalToBool(YES)));
}

- (void)testShouldParseRelativelyComplexXML {
    NSString *XML = RKSpecReadFixture(@"national_weather_service.xml");
    RKXMLParserLibXML* parser = [[RKXMLParserLibXML new] autorelease];
    NSException *exception = nil;
    @try {
        [parser parseXML:XML];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(nilValue()));
    }
}

@end
