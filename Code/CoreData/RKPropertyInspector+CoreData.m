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
#import "RKBooleanClass.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

@interface RKPropertyInspector ()
@property (nonatomic, assign) dispatch_queue_t queue;
@property (nonatomic, strong) NSMutableDictionary *inspectionCache;
@end

@implementation RKPropertyInspector (CoreData)

- (NSDictionary *)propertyInspectionForEntity:(NSEntityDescription *)entity
{
    __block NSMutableDictionary *entityInspection;
    dispatch_sync(self.queue, ^{
        entityInspection = (self.inspectionCache)[[entity name]];
    });
    if (entityInspection) return entityInspection;

    entityInspection = [NSMutableDictionary dictionary];
    for (NSString *name in [entity attributesByName]) {
        NSAttributeDescription *attributeDescription = [[entity attributesByName] valueForKey:name];
        if ([attributeDescription attributeValueClassName]) {
            Class cls = NSClassFromString([attributeDescription attributeValueClassName]);
            if ([cls isSubclassOfClass:[NSNumber class]] && [attributeDescription attributeType] == NSBooleanAttributeType) {
                cls = RK_BOOLEAN_CLASS;
            }
            RKPropertyInspectorPropertyInfo *info;
            info = [RKPropertyInspectorPropertyInfo propertyInfoWithName:name
                                                           keyValueClass:cls
                                                             isPrimitive:NO];
            [entityInspection setValue:info forKey:name];

        } else if ([attributeDescription attributeType] == NSTransformableAttributeType &&
                   ![name isEqualToString:@"_mapkit_hasPanoramaID"]) {

            const char *className = [[entity managedObjectClassName] cStringUsingEncoding:NSUTF8StringEncoding];
            const char *propertyName = [name cStringUsingEncoding:NSUTF8StringEncoding];
            Class managedObjectClass = objc_getClass(className);

            objc_property_t prop = class_getProperty(managedObjectClass, propertyName);
            
            // Property is not defined in the Core Data model -- we cannot infer any details about the destination type
            if (prop) {
                const char *attr = property_getAttributes(prop);
                Class destinationClass = RKKeyValueCodingClassFromPropertyAttributes(attr);
                if (destinationClass) {
                    RKPropertyInspectorPropertyInfo *info;
                    info = [RKPropertyInspectorPropertyInfo propertyInfoWithName:name
                                                                   keyValueClass:destinationClass
                                                                     isPrimitive:NO];
                    entityInspection[name] = info;
                }
            }
        }
    }

    for (NSString *name in [entity relationshipsByName]) {
        NSRelationshipDescription *relationshipDescription = [[entity relationshipsByName] valueForKey:name];
        if ([relationshipDescription isToMany]) {
            if ([relationshipDescription isOrdered]) {
                RKPropertyInspectorPropertyInfo *info;
                info = [RKPropertyInspectorPropertyInfo propertyInfoWithName:name
                                                               keyValueClass:[NSOrderedSet class]
                                                                 isPrimitive:NO];
                entityInspection[name] = info;
            } else {
                RKPropertyInspectorPropertyInfo *info;
                info = [RKPropertyInspectorPropertyInfo propertyInfoWithName:name
                                                               keyValueClass:[NSSet class]
                                                                 isPrimitive:NO];
                entityInspection[name] = info;
            }
        } else {
            NSEntityDescription *destinationEntity = [relationshipDescription destinationEntity];
            Class destinationClass = NSClassFromString([destinationEntity managedObjectClassName]);
            if (! destinationClass) {
                RKLogWarning(@"Retrieved `Nil` value for class named '%@': This likely indicates that the class is invalid or does not exist in the current target.", [destinationEntity managedObjectClassName]);
            }
            RKPropertyInspectorPropertyInfo *info;
            info = [RKPropertyInspectorPropertyInfo propertyInfoWithName:name
                                                           keyValueClass:destinationClass ?: [NSNull null]
                                                             isPrimitive:NO];
            entityInspection[name] = info;
        }
    }

    dispatch_barrier_async(self.queue, ^{
        (self.inspectionCache)[[entity name]] = entityInspection;
        RKLogDebug(@"Cached property inspection for Entity '%@': %@", entity, entityInspection);
    });
    return entityInspection;
}

- (Class)classForPropertyNamed:(NSString *)propertyName ofEntity:(NSEntityDescription *)entity
{
    NSDictionary *entityInspection = [self propertyInspectionForEntity:entity];
    RKPropertyInspectorPropertyInfo *propertyInspection = entityInspection[propertyName];
    return propertyInspection.keyValueCodingClass;
}

@end

@interface NSManagedObject (RKPropertyInspection)
- (Class)rk_classForPropertyAtKeyPath:(NSString *)keyPath isPrimitive:(BOOL *)isPrimitive;
@end

@implementation NSManagedObject (RKPropertyInspection)

- (Class)rk_classForPropertyAtKeyPath:(NSString *)keyPath isPrimitive:(BOOL *)isPrimitive
{
    NSRange dotRange = [keyPath rangeOfString:@"." options:NSLiteralSearch];
    RKPropertyInspector *inspector = [RKPropertyInspector sharedInspector];
    Class currentPropertyClass = [self class];
    Class propertyClass = nil;

    if (dotRange.length == 0) {
        propertyClass = [inspector classForPropertyNamed:keyPath ofEntity:[self entity]];
        return propertyClass ?: [inspector classForPropertyNamed:keyPath ofClass:currentPropertyClass isPrimitive:isPrimitive];
    }

    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    for (NSString *property in components) {
        if (isPrimitive) *isPrimitive = NO; // Core Data does not enable you to model primitives
        propertyClass = [inspector classForPropertyNamed:property ofEntity:[self entity]];
        propertyClass = propertyClass ?: [inspector classForPropertyNamed:property ofClass:currentPropertyClass isPrimitive:isPrimitive];
        if (! propertyClass) break;
        currentPropertyClass = propertyClass;
    }
    
    return propertyClass;
}

@end
