//
//  TestSerialization.m
//  OTRestFramework
//
//  Created by Jeremy Ellison on 8/17/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "TestSerialization.h"


@implementation TestSerialization

@synthesize dateTest = _dateTest, numberTest = _numberTest, stringTest = _stringTest,
hasOne = _hasOne, hasMany = _hasMany;

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"dateTest", @"date_test",
			@"numberTest", @"number_test",
			@"stringTest", @"string_test", nil];
}

+ (NSDictionary*)elementToRelationshipMappings {
	return [NSDictionary dictionaryWithObjectsAndKeys:@"hasOne", @"has_one",
			@"hasMany", @"has_manys > has_many", nil];
}

@end
