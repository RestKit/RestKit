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

static char primaryKeyAttributeNameKey, primaryKeyPredicateKey;

@implementation NSEntityDescription (RKAdditions)

- (void)setPredicateForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
{
    NSPredicate *predicate = (primaryKeyAttribute) ? [NSPredicate predicateWithFormat:@"%K == $PRIMARY_KEY_VALUE", primaryKeyAttribute] : nil;
    objc_setAssociatedObject(self,
                             &primaryKeyPredicateKey,
                             predicate,
                             OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - Public

- (NSAttributeDescription *)primaryKeyAttribute
{
    return [[self attributesByName] valueForKey:[self primaryKeyAttributeName]];
}

- (Class)primaryKeyAttributeClass
{
    NSAttributeDescription *attributeDescription = [self primaryKeyAttribute];
    if (attributeDescription) {
        return NSClassFromString(attributeDescription.attributeValueClassName);
    }

    return nil;
}

- (NSString *)primaryKeyAttributeName
{
    // Check for an associative object reference
    NSString *primaryKeyAttribute = (NSString *)objc_getAssociatedObject(self, &primaryKeyAttributeNameKey);

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

- (void)setPrimaryKeyAttributeName:(NSString *)primaryKeyAttributeName
{
    objc_setAssociatedObject(self,
                             &primaryKeyAttributeNameKey,
                             primaryKeyAttributeName,
                             OBJC_ASSOCIATION_RETAIN);
    [self setPredicateForPrimaryKeyAttribute:primaryKeyAttributeName];
}

- (NSPredicate *)predicateForPrimaryKeyAttribute
{
    return (NSPredicate *)objc_getAssociatedObject(self, &primaryKeyPredicateKey);
}

- (id)coerceValueForPrimaryKey:(id)primaryKeyValue
{
    id searchValue = primaryKeyValue;
    Class theClass = [self primaryKeyAttributeClass];
    if (theClass) {
        // TODO: This coercsion behavior should be pluggable and reused from the mapper
        if ([theClass isSubclassOfClass:[NSNumber class]] && ![searchValue isKindOfClass:[NSNumber class]]) {
            // Handle NSString -> NSNumber
            if ([searchValue isKindOfClass:[NSString class]]) {
                searchValue = [NSNumber numberWithDouble:[searchValue doubleValue]];
            }
        } else if ([theClass isSubclassOfClass:[NSString class]] && ![searchValue isKindOfClass:[NSString class]]) {
            // Coerce to string
            if ([searchValue respondsToSelector:@selector(stringValue)]) {
                searchValue = [searchValue stringValue];
            }
        }
    }

    return searchValue;
}

- (NSPredicate *)predicateForPrimaryKeyAttributeWithValue:(id)value
{
    id substitutionValue = [self coerceValueForPrimaryKey:value];
    NSDictionary *variables = [NSDictionary dictionaryWithObject:substitutionValue
                                                          forKey:RKEntityDescriptionPrimaryKeyAttributeValuePredicateSubstitutionVariable];
    return [[self predicateForPrimaryKeyAttribute] predicateWithSubstitutionVariables:variables];
}

@end
