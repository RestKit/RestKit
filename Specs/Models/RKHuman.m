//
//  Human.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKHuman.h"
#import "NSDictionary+RKAdditions.h"

@implementation RKHuman

@dynamic railsID;
@dynamic name;
@dynamic nickName;
@dynamic birthday;
@dynamic sex;
@dynamic age;
@dynamic createdAt;
@dynamic updatedAt;

@dynamic favoriteCat;
@dynamic cats;

- (NSString*)polymorphicResourcePath {
	return @"/this/is/the/path";
}

@end
