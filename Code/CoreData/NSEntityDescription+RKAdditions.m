//
//  NSEntityDescription+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 3/22/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <objc/runtime.h>
#import "NSEntityDescription+RKAdditions.h"

NSString * const RKEntityDescriptionPrimaryKeyAttributeUserInfoKey = @"primaryKeyAttribute";
static char primaryKeyAttributeKey;

@implementation NSEntityDescription (RKAdditions)

- (NSString *)primaryKeyAttribute
{
    // Check for an associative object reference
    NSString *primaryKeyAttribute = (NSString *) objc_getAssociatedObject(self, &primaryKeyAttributeKey);

    // Fall back to the userInfo dictionary
    if (! primaryKeyAttribute) {
        primaryKeyAttribute = [self.userInfo valueForKey:RKEntityDescriptionPrimaryKeyAttributeUserInfoKey];
    }

    return primaryKeyAttribute;
}

- (void)setPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
{
    objc_setAssociatedObject(self,
                             &primaryKeyAttributeKey,
                             primaryKeyAttribute,
                             OBJC_ASSOCIATION_RETAIN);
}

@end
