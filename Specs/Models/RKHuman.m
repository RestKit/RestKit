//
//  Human.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKHuman.h"

@implementation RKHuman

@dynamic railsID;
@dynamic name;
@dynamic nickName;
@dynamic birthday;
@dynamic sex;
@dynamic age;
@dynamic createdAt;
@dynamic updatedAt;

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"name", @"name",
			@"nickName", @"nick-name",
			@"birthday", @"birthday",
			@"sex", @"sex",
			@"age", @"age",
			@"createdAt", @"created-at",
			@"updatedAt", @"updated-at",
			@"railsID", @"id",
			nil];
}

- (NSString*)polymorphicResourcePath {
	return @"/this/is/the/path";
}

+ (NSString*)primaryKeyProperty {
	return @"railsID";
}

@end
