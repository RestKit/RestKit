//
//  RKObjectPropertyInspector+CoreData.m
//  RestKit
//
//  Created by Blake Watters on 8/14/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKObjectPropertyInspector+CoreData.h"
#import "../Support/RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@implementation RKObjectPropertyInspector (CoreData)

- (NSDictionary *)propertyNamesAndTypesForEntity:(NSEntityDescription*)entity {
    NSMutableDictionary* propertyNamesAndTypes = [_cachedPropertyNamesAndTypes objectForKey:[entity name]];
	if (propertyNamesAndTypes) {
		return propertyNamesAndTypes;
	}
    
    propertyNamesAndTypes = [NSMutableDictionary dictionary];
    for (NSString* name in [entity attributesByName]) {
        NSAttributeDescription* attributeDescription = [[entity attributesByName] valueForKey:name];
        [propertyNamesAndTypes setValue:NSClassFromString([attributeDescription attributeValueClassName]) forKey:name];
    }
    
    for (NSString* name in [entity relationshipsByName]) {
        NSRelationshipDescription* relationshipDescription = [[entity relationshipsByName] valueForKey:name];
        if ([relationshipDescription isToMany]) {
            [propertyNamesAndTypes setValue:[NSSet class] forKey:name];
        } else {
            NSEntityDescription* destinationEntity = [relationshipDescription destinationEntity];
            Class destinationClass = NSClassFromString([destinationEntity managedObjectClassName]);
            [propertyNamesAndTypes setValue:destinationClass forKey:name];
        }
    }
    
    [_cachedPropertyNamesAndTypes setObject:propertyNamesAndTypes forKey:[entity name]];
    RKLogDebug(@"Cached property names and types for Entity '%@': %@", entity, propertyNamesAndTypes);
    return propertyNamesAndTypes;
}

- (Class)typeForProperty:(NSString*)propertyName ofEntity:(NSEntityDescription*)entity {
    return [[self propertyNamesAndTypesForEntity:entity] valueForKey:propertyName];
}

@end
