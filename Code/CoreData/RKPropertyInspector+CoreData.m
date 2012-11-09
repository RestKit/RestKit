//
//  RKPropertyInspector+CoreData.m
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
#import <objc/message.h>
#import "RKPropertyInspector+CoreData.h"
#import "RKLog.h"
#import "RKObjectUtilities.h"
#import "RKMacros.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

@implementation RKPropertyInspector (CoreData)

- (NSDictionary *)propertyNamesAndClassesForEntity:(NSEntityDescription *)entity
{
    NSMutableDictionary *propertyNamesAndTypes = [_propertyNamesToTypesCache objectForKey:[entity name]];
    if (propertyNamesAndTypes) {
        return propertyNamesAndTypes;
    }

    propertyNamesAndTypes = [NSMutableDictionary dictionary];
    for (NSString *name in [entity attributesByName]) {
        NSAttributeDescription *attributeDescription = [[entity attributesByName] valueForKey:name];
        if ([attributeDescription attributeValueClassName]) {
            Class cls = NSClassFromString([attributeDescription attributeValueClassName]);
            if ([cls isSubclassOfClass:[NSNumber class]] && [attributeDescription attributeType] == NSBooleanAttributeType) {
                cls = objc_getClass("NSCFBoolean") ?: objc_getClass("__NSCFBoolean") ?: cls;
            }
            [propertyNamesAndTypes setValue:cls forKey:name];

        } else if ([attributeDescription attributeType] == NSTransformableAttributeType &&
                   ![name isEqualToString:@"_mapkit_hasPanoramaID"]) {

            const char *className = [[entity managedObjectClassName] cStringUsingEncoding:NSUTF8StringEncoding];
            const char *propertyName = [name cStringUsingEncoding:NSUTF8StringEncoding];
            Class managedObjectClass = objc_getClass(className);

            objc_property_t prop = class_getProperty(managedObjectClass, propertyName);

            const char *attr = property_getAttributes(prop);
            Class destinationClass = RKKeyValueCodingClassFromPropertyAttributes(attr);
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

    [_propertyNamesToTypesCache setObject:propertyNamesAndTypes forKey:[entity name]];
    RKLogDebug(@"Cached property names and types for Entity '%@': %@", entity, propertyNamesAndTypes);
    return propertyNamesAndTypes;
}

- (Class)classForPropertyNamed:(NSString *)propertyName ofEntity:(NSEntityDescription *)entity
{
    return [[self propertyNamesAndClassesForEntity:entity] valueForKey:propertyName];
}

@end

@interface NSManagedObject (RKPropertyInspection)
- (Class)rk_classForPropertyAtKeyPath:(NSString *)keyPath;
@end

@implementation NSManagedObject (RKPropertyInspection)

- (Class)rk_classForPropertyAtKeyPath:(NSString *)keyPath
{
    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    Class propertyClass = [self class];
    for (NSString *property in components) {
        propertyClass = [[RKPropertyInspector sharedInspector] classForPropertyNamed:property ofEntity:[self entity]];
        propertyClass = propertyClass ?: [[RKPropertyInspector sharedInspector] classForPropertyNamed:property ofClass:propertyClass];
        if (! propertyClass) break;
    }
    
    return propertyClass;
}

@end
