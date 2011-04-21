//
//  User.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "User.h"

@implementation User

@dynamic userID;
@dynamic name;
@dynamic email;
@dynamic tasks;

+ (NSDictionary*)elementToPropertyMappings {
    return [NSDictionary dictionaryWithKeysAndObjects:
            @"id", @"userID",
            @"name", @"name",
            @"email", @"email",
            nil];
}

+ (NSString*)primaryKeyProperty {
    return @"userID";
}

+ (NSDictionary*)elementToRelationshipMappings {
    return [NSDictionary dictionaryWithKeysAndObjects:
            @"tasks", @"tasks",
            nil];
}

@end
