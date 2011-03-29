//
//  RKXMLParserSpec.m
//  RestKit
//
//  Created by Jeremy Ellison on 3/29/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKXMLParser.h"

@interface RKXMLParserSpec : NSObject <UISpec> {
    
}

@end

@implementation RKXMLParserSpec

- (void)itShouldMapASingleXMLObjectPayloadToADictionary {
    NSString* data = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  <float type=\"float\">2.4</float>\n  <string>string</string>\n  <number type=\"integer\">1</number>\n</hash>\n";
    id result = [RKXMLParser parse:data];
    [expectThat(NSStringFromClass([result class])) should:be(@"__NSCFDictionary")];
    [expectThat([[result valueForKeyPath:@"hash.float"] floatValue]) should:be(2.4f)];
    [expectThat([[result valueForKeyPath:@"hash.number"] intValue]) should:be(1)];
    [expectThat([result valueForKeyPath:@"hash.string"]) should:be(@"string")];
}

- (void)itShouldMapMultipleObjectsToAnArray {
    NSString* data = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<records type=\"array\">\n  <record>\n    <float type=\"float\">2.4</float>\n    <string>string</string>\n    <number type=\"integer\">1</number>\n  </record>\n  <record>\n    <another-number type=\"integer\">1</another-number>\n  </record>\n</records>\n";
    {
        // Parse Raw Data
        id result = [RKXMLParser parse:data];
        NSArray* records = (NSArray*)[result valueForKeyPath:@"records"];
        [expectThat([records count]) should:be(2)];
        id result1 = [records objectAtIndex:0];
        [expectThat(NSStringFromClass([result1 class])) should:be(@"__NSCFDictionary")];
        [expectThat([[result1 valueForKeyPath:@"record.float"] floatValue]) should:be(2.4f)];
        [expectThat([[result1 valueForKeyPath:@"record.number"] intValue]) should:be(1)];
        [expectThat([result1 valueForKeyPath:@"record.string"]) should:be(@"string")];
        id result2 = [records objectAtIndex:1];
        [expectThat([[result2 valueForKeyPath:@"record.another-number"] intValue]) should:be(1)];
    }
    {
        // Simulate using a keypath to extract records array
        NSArray* result = (NSArray*)[[RKXMLParser parse:data] valueForKeyPath:@"records.record"];
        [expectThat([result count]) should:be(2)];
        id result1 = [result objectAtIndex:0];
        [expectThat(NSStringFromClass([result1 class])) should:be(@"__NSCFDictionary")];
        [expectThat([[result1 valueForKeyPath:@"float"] floatValue]) should:be(2.4f)];
        [expectThat([[result1 valueForKeyPath:@"number"] intValue]) should:be(1)];
        [expectThat([result1 valueForKeyPath:@"string"]) should:be(@"string")];
        id result2 = [result objectAtIndex:1];
        [expectThat([[result2 valueForKeyPath:@"another-number"] intValue]) should:be(1)];
    }
}

@end
