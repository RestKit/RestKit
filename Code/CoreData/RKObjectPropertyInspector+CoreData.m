//
//  RKObjectPropertyInspector+CoreData.m
//  RestKit
//
//  Created by Blake Watters on 8/14/11.
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

#import <CoreData/CoreData.h>
#import "RKObjectPropertyInspector+CoreData.h"
#import "RKLog.h"
#import "RKFixCategoryBug.h"
#import <objc/message.h>


RK_FIX_CATEGORY_BUG(RKObjectPropertyInspector_CoreData)

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@implementation RKObjectPropertyInspector (CoreData)

- (NSDictionary *)propertyNamesAndTypesForEntity:(NSEntityDescription *)entity
{
    NSMutableDictionary *propertyNamesAndTypes = [_cachedPropertyNamesAndTypes objectForKey:[entity name]];
    if (propertyNamesAndTypes) {
        return propertyNamesAndTypes;
    }

    propertyNamesAndTypes = [NSMutableDictionary dictionary];
    for (NSString *name in [entity attributesByName]) {
        NSAttributeDescription *attributeDescription = [[entity attributesByName] valueForKey:name];
        if ([attributeDescription attributeValueClassName]) {
            [propertyNamesAndTypes setValue:NSClassFromString([attributeDescription attributeValueClassName]) forKey:name];

        } else if ([attributeDescription attributeType] == NSTransformableAttributeType &&
                   ![name isEqualToString:@"_mapkit_hasPanoramaID"]) {

            const char *className = [[entity managedObjectClassName] cStringUsingEncoding:NSUTF8StringEncoding];
            const char *propertyName = [name cStringUsingEncoding:NSUTF8StringEncoding];
            Class managedObjectClass = objc_getClass(className);

            // property_getAttributes() returns everything we need to implement this...
            // See: http://developer.apple.com/mac/library/DOCUMENTATION/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW5
            objc_property_t prop = class_getProperty(managedObjectClass, propertyName);
            NSString *attributeString = [NSString stringWithCString:property_getAttributes(prop) encoding:NSUTF8StringEncoding];
            const char *destinationClassName = [[RKObjectPropertyInspector propertyTypeFromAttributeString:attributeString] cStringUsingEncoding:NSUTF8StringEncoding];
            Class destinationClass = objc_getClass(destinationClassName);
            if (destinationClass) {
                [propertyNamesAndTypes setObject:destinationClass forKey:name];
            }
        }
    }

    for (NSString *name in [entity relationshipsByName]) {
        NSRelationshipDescription *relationshipDescription = [[entity relationshipsByName] valueForKey:name];
        if ([relationshipDescription isToMany]) {
            [propertyNamesAndTypes setValue:[NSSet class] forKey:name];
        } else {
            NSEntityDescription *destinationEntity = [relationshipDescription destinationEntity];
            Class destinationClass = NSClassFromString([destinationEntity managedObjectClassName]);
            [propertyNamesAndTypes setValue:destinationClass forKey:name];
        }
    }

    [_cachedPropertyNamesAndTypes setObject:propertyNamesAndTypes forKey:[entity name]];
    RKLogDebug(@"Cached property names and types for Entity '%@': %@", entity, propertyNamesAndTypes);
    return propertyNamesAndTypes;
}

- (Class)typeForProperty:(NSString *)propertyName ofEntity:(NSEntityDescription *)entity
{
    return [[self propertyNamesAndTypesForEntity:entity] valueForKey:propertyName];
}

@end
