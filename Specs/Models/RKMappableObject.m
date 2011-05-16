//
//  RKMappableObject.m
//  RestKit
//
//  Created by Jeremy Ellison on 8/17/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKMappableObject.h"
#import "NSDictionary+RKAdditions.h"

@implementation RKMappableObject

@synthesize dateTest = _dateTest, numberTest = _numberTest, stringTest = _stringTest, urlTest = _urlTest,
decimalNumberTest = _decimalNumberTest, hasOne = _hasOne, hasMany = _hasMany;

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:@"date_test", @"dateTest", 
					@"number_test", @"numberTest", 
					@"string_test", @"stringTest",
					@"url_test", @"urlTest",
					@"decimal_number_test", @"decimalNumberTest",
					nil];
}

+ (NSDictionary*)elementToRelationshipMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"has_one", @"hasOne",
			@"has_manys.@unionOfObjects.has_many", @"hasMany", 
			nil];
}

+ (NSArray*)relationshipsToSerialize {
    return [NSArray array];
}

@end
