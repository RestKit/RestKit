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
NSString * const RKEntityDescriptionPrimaryKeyAttributeValuePredicateSubstitutionVariable = @"PRIMARY_KEY_VALUE";

static char primaryKeyAttributeKey, primaryKeyPredicateKey;

@implementation NSEntityDescription (RKAdditions)

- (void)setPredicateForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == $PRIMARY_KEY_VALUE", primaryKeyAttribute];
    objc_setAssociatedObject(self,
                             &primaryKeyPredicateKey,
                             predicate,
                             OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - Public

- (NSString *)primaryKeyAttribute
{
    // Check for an associative object reference
    NSString *primaryKeyAttribute = (NSString *) objc_getAssociatedObject(self, &primaryKeyAttributeKey);

    // Fall back to the userInfo dictionary
    if (! primaryKeyAttribute) {
        primaryKeyAttribute = [self.userInfo valueForKey:RKEntityDescriptionPrimaryKeyAttributeUserInfoKey];
        
        // If we have loaded from the user info, ensure we have a predicate
        if (! [self predicateForPrimaryKeyAttribute]) {
            [self setPredicateForPrimaryKeyAttribute:primaryKeyAttribute];
        }
    }

    return primaryKeyAttribute;
}

- (void)setPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
{
    objc_setAssociatedObject(self,
                             &primaryKeyAttributeKey,
                             primaryKeyAttribute,
                             OBJC_ASSOCIATION_RETAIN);    
    [self setPredicateForPrimaryKeyAttribute:primaryKeyAttribute];
}


- (NSPredicate *)predicateForPrimaryKeyAttribute
{
    return (NSPredicate *) objc_getAssociatedObject(self, &primaryKeyPredicateKey);
}

- (NSPredicate *)predicateForPrimaryKeyAttributeWithValue:(id)value
{
    NSDictionary *variables = [NSDictionary dictionaryWithObject:value
                                                          forKey:RKEntityDescriptionPrimaryKeyAttributeValuePredicateSubstitutionVariable];
    return [[self predicateForPrimaryKeyAttribute] predicateWithSubstitutionVariables:variables];
}

@end
