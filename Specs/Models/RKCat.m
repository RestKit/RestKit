//
//  RKCat.m
//  RestKit
//
//  Created by Jeremy Ellison on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKCat.h"


@implementation RKCat

@dynamic age;
@dynamic birthYear;
@dynamic color;
@dynamic createdAt;
@dynamic humanId;
@dynamic name;
@dynamic nickName;
@dynamic railsID;
@dynamic sex;
@dynamic updatedAt;

@dynamic human;

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"name", @"name",
			@"nickName", @"nick-name",
			@"birthYear", @"birth_year",
			@"sex", @"sex",
			@"age", @"age",
			@"createdAt", @"created-at",
			@"updatedAt", @"updated-at",
			@"railsID", @"id",
			nil];
}

+ (NSString*)primaryKeyProperty {
	return @"railsID";
}

+ (NSDictionary*)elementToRelationshipMappings {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"human", @"human",
            nil];
}

+ (NSArray*)relationshipsToSerialize {
    return [NSArray arrayWithObject:@"human"];
}

@end
