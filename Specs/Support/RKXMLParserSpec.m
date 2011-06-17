//
//  RKXMLParserLibXMLSpec.m
//  RestKit
//
//  Created by Jeremy Ellison on 3/29/11.
//  Copyright 2011 Two Toasters. All rights reserved.
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

- (void)itShouldMapASingleXMLObjectPayloadToADictionary {
    NSString* data = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  <float type=\"float\">2.4</float>\n  <string>string</string>\n  <number type=\"integer\">1</number>\n</hash>\n";
    RKXMLParserLibXML* parser = [[RKXMLParserLibXML new] autorelease];
    id result = [parser parseXML:data];
    [expectThat(NSStringFromClass([result class])) should:be(@"__NSCFDictionary")];
    [expectThat([[result valueForKeyPath:@"hash.float"] floatValue]) should:be(2.4f)];
    [expectThat([[result valueForKeyPath:@"hash.number"] intValue]) should:be(1)];
    [expectThat([result valueForKeyPath:@"hash.string"]) should:be(@"string")];
}

- (void)itShouldMapMultipleObjectsToAnArray {
    NSString* data = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records type=\"array\">\n  <record>\n    <float type=\"float\">2.4</float>\n    <string>string</string>\n    <number type=\"integer\">1</number>\n  </record>\n  <record>\n    <another-number type=\"integer\">1</another-number>\n  </record>\n</records>\n";
    RKXMLParserLibXML* parser = [[RKXMLParserLibXML new] autorelease];
    id result = [parser parseXML:data];
    NSArray* records = (NSArray*)[result valueForKeyPath:@"records.record"];
    [expectThat([records count]) should:be(2)];
    id result1 = [records objectAtIndex:0];
    [expectThat(NSStringFromClass([result1 class])) should:be(@"__NSCFDictionary")];
    [expectThat([[result1 valueForKeyPath:@"float"] floatValue]) should:be(2.4f)];
    [expectThat([[result1 valueForKeyPath:@"number"] intValue]) should:be(1)];
    [expectThat([result1 valueForKeyPath:@"string"]) should:be(@"string")];
    id result2 = [records objectAtIndex:1];
    [expectThat([[result2 valueForKeyPath:@"another-number"] intValue]) should:be(1)];
}

- (void)itShouldMapXML {
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKSpecTabData class]];
    [mapping mapAttributes:@"title", @"summary", nil];
    RKObjectMappingProvider* provider = [[RKObjectMappingProvider alloc] init];
    id data = RKSpecParseFixture(@"tab_data.xml");
    NSLog(@"%@", data);
    assertThat([data valueForKeyPath:@"tabdata.item"], is(instanceOf([NSArray class])));
    [provider setMapping:mapping forKeyPath:@"tabdata.item"];
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:data mappingProvider:provider];
    RKObjectMappingResult* result = [mapper performMapping];
    assertThatInt([[result asCollection] count], is(equalToInt(2)));
    assertThatInt([[data valueForKeyPath:@"tabdata.title"] count], is(equalToInt(2)));
    assertThatInt([[data valueForKeyPath:@"tabdata.item"] count], is(equalToInt(2)));
}

@end
