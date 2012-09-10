//
//  NSEntityDescription+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 3/22/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <objc/runtime.h>
#import "NSEntityDescription+RKAdditions.h"

NSString * const RKEntityDescriptionPrimaryKeyAttributeUserInfoKey = @"primaryKeyAttribute";
NSString * const RKEntityDescriptionPrimaryKeyAttributeValuePredicateSubstitutionVariable = @"PRIMARY_KEY_VALUE";

static char primaryKeyPredicateKey;

@implementation NSEntityDescription (RKAdditions)

- (void)setPredicateForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
{
    NSPredicate *predicate = (primaryKeyAttribute) ? [NSPredicate predicateWithFormat:@"%K == $PRIMARY_KEY_VALUE", primaryKeyAttribute] : nil;
    objc_setAssociatedObject(self,
                             &primaryKeyPredicateKey,
                             predicate,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    NSString *primaryKeyAttribute = [self.userInfo valueForKey:RKEntityDescriptionPrimaryKeyAttributeUserInfoKey];

    // If we have loaded from the user info, ensure we have a predicate
    if (! [self predicateForPrimaryKeyAttribute]) {
        [self setPredicateForPrimaryKeyAttribute:primaryKeyAttribute];
    }

    return primaryKeyAttribute;
}

- (void)setPrimaryKeyAttributeName:(NSString *)primaryKeyAttributeName
{
    NSMutableDictionary *userInfo = [self.userInfo mutableCopy];
    [userInfo setValue:primaryKeyAttributeName forKey:RKEntityDescriptionPrimaryKeyAttributeUserInfoKey];
    [self setUserInfo:userInfo];
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
