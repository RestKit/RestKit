//
//  RKEntityIdentifier.m
//  RestKit
//
//  Created by Blake Watters on 11/20/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKEntityIdentifier.h"
#import "RKManagedObjectStore.h"

NSString * const RKEntityIdentifierUserInfoKey = @"RKEntityIdentifierAttributes";

static NSArray *RKEntityIdentifierAttributesFromUserInfoOfEntity(NSEntityDescription *entity)
{
    id userInfoValue = [entity userInfo][RKEntityIdentifierUserInfoKey];
    if (userInfoValue) {
        NSArray *attributeNames = [userInfoValue isKindOfClass:[NSArray class]] ? userInfoValue : @[ userInfoValue ];
        NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:[attributeNames count]];
        [attributeNames enumerateObjectsUsingBlock:^(NSString *attributeName, NSUInteger idx, BOOL *stop) {
            if (! [attributeName isKindOfClass:[NSString class]]) {
                [NSException raise:NSInvalidArgumentException format:@"Invalid value given in user info key '%@' of entity '%@': expected an `NSString` or `NSArray` of strings, instead got '%@' (%@)", RKEntityIdentifierUserInfoKey, [entity name], attributeName, [attributeName class]];
            }
            
            NSAttributeDescription *attribute = [entity attributesByName][attributeName];
            if (! attribute) {
                [NSException raise:NSInvalidArgumentException format:@"Invalid identifier attribute specified in user info key '%@' of entity '%@': no attribue was found with the name '%@'", RKEntityIdentifierUserInfoKey, [entity name], attributeName];
            }
            
            [attributes addObject:attribute];
        }];
        return attributes;
    }
    
    return nil;
}

// Given 'Human', returns 'humanID'; Given 'AmenityReview' returns 'amenityReviewID'
static NSString *RKEntityIdentifierAttributeNameForEntity(NSEntityDescription *entity)
{
    NSString *entityName = [entity name];
    NSString *lowerCasedFirstCharacter = [[entityName substringToIndex:1] lowercaseString];
    return [NSString stringWithFormat:@"%@%@ID", lowerCasedFirstCharacter, [entityName substringFromIndex:1]];
}

static NSArray *RKEntityIdentifierAttributeNames()
{
    return [NSArray arrayWithObjects:@"identifier", @"ID", @"URL", @"url", nil];
}

static NSArray *RKArrayOfAttributesForEntityFromAttributesOrNames(NSEntityDescription *entity, NSArray *attributesOrNames)
{
    NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:[attributesOrNames count]];
    for (id attributeOrName in attributesOrNames) {
        if ([attributeOrName isKindOfClass:[NSAttributeDescription class]]) {
            if (! [[entity properties] containsObject:attributeOrName]) [NSException raise:NSInvalidArgumentException format:@"Invalid attribute value '%@' given for entity identifer: not found in the '%@' entity", attributeOrName, [entity name]];
            [attributes addObject:attributeOrName];
        } else if ([attributeOrName isKindOfClass:[NSString class]]) {
            NSAttributeDescription *attribute = [entity attributesByName][attributeOrName];
            if (!attribute) [NSException raise:NSInvalidArgumentException format:@"Invalid attribute '%@': no attribute was found for the given name in the '%@' entity.", attributeOrName, [entity name]];
            [attributes addObject:attribute];
        } else {
            [NSException raise:NSInvalidArgumentException format:@"Invalid value provided for entity identifier attribute: Acceptable values are either `NSAttributeDescription` or `NSString` objects."];
        }
    }
    
    return attributes;
}

@interface RKEntityIdentifier ()
@property (nonatomic, strong, readwrite) NSEntityDescription *entity;
@property (nonatomic, copy, readwrite) NSArray *attributes;
@end

@implementation RKEntityIdentifier

+ (id)identifierWithEntityName:(NSString *)entityName attributes:(NSArray *)attributes inManagedObjectStore:(RKManagedObjectStore *)managedObjectStore
{
    NSEntityDescription *entity = [managedObjectStore.managedObjectModel entitiesByName][entityName];
    return [[self alloc] initWithEntity:entity attributes:attributes];
}

- (id)initWithEntity:(NSEntityDescription *)entity attributes:(NSArray *)attributes
{
    NSParameterAssert(entity);
    NSParameterAssert(attributes);
    NSAssert([attributes count], @"At least one attribute must be provided to identify managed objects");
    self = [self init];
    if (self) {
        self.entity = entity;
        self.attributes = RKArrayOfAttributesForEntityFromAttributesOrNames(entity, attributes);
    }
    
    return self;
}

#pragma mark - Idetifier Inference

+ (RKEntityIdentifier *)inferredIdentifierForEntity:(NSEntityDescription *)entity
{
    NSArray *attributes = RKEntityIdentifierAttributesFromUserInfoOfEntity(entity);
    if (attributes) {
        return [[RKEntityIdentifier alloc] initWithEntity:entity attributes:attributes];
    }
    
    NSMutableArray *identifyingAttributes = [NSMutableArray arrayWithObject:RKEntityIdentifierAttributeNameForEntity(entity)];
    [identifyingAttributes addObjectsFromArray:RKEntityIdentifierAttributeNames()];
    for (NSString *attributeName in identifyingAttributes) {
        NSAttributeDescription *attribute = [entity attributesByName][attributeName];
        if (attribute) {
            return [[RKEntityIdentifier alloc] initWithEntity:entity attributes:@[ attribute ]];
        }
    }
    return nil;
}

@end
