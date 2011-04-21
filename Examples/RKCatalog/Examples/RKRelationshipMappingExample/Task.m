//
//  Task.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "Task.h"

@implementation Task

@dynamic name;
@dynamic taskID;
@dynamic assignedUserID;
@dynamic assignedUser;

+ (NSDictionary*)elementToPropertyMappings {
    return [NSDictionary dictionaryWithKeysAndObjects:
            @"id", @"taskID",
            @"name", @"name",
            @"assigned_user_id", @"assignedUserID",
            nil];
}

+ (NSString*)primaryKeyProperty {
    return @"taskID";
}

+ (NSDictionary*)relationshipToPrimaryKeyPropertyMappings {
    return [NSDictionary dictionaryWithObject:@"assignedUserID" forKey:@"assignedUser"];
}

@end
