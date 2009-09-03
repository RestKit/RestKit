//
//  OTRestModelMapperTest.h
//  OTRestFramework
//
//  Created by Jeremy Ellison on 8/17/09.
//  Copyright 2009 Objective3. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

//  Dependent unit tests mean unit test code depends on an application to be injected into.
//  Setting this to 0 means the unit test code is designed to be linked into an independent executable.
#define USE_DEPENDENT_UNIT_TEST 1

#import <SenTestingKit/SenTestingKit.h>
//#import "application_headers" as required


@interface OTRestModelMapperTest : SenTestCase {

}

- (void)testIsParentSelector;
- (void)testContainingElementNameForSelector;
- (void)testChildElementNameForSelector;


- (void)testJSONMapping;
- (void)testJSONCollectionMapping;

- (void)testXMLMapping;
- (void)testXMLCollectionMapping;

@end
