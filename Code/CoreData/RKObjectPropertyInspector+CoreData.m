//
//  RKObjectPropertyInspector+CoreData.m
//  RestKit
//
//  Created by Blake Watters on 8/14/11.
//  Copyright 2011 RestKit
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

#import <CoreData/CoreData.h>
#import "RKObjectPropertyInspector+CoreData.h"
#import "RKLog.h"
#import "RKFixCategoryBug.h"

RK_FIX_CATEGORY_BUG(RKObjectPropertyInspector_CoreData)

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
