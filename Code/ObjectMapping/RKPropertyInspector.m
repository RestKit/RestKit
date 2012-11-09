//
//  RKPropertyInspector.m
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
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
#import "RKPropertyInspector.h"
#import "RKLog.h"
#import "RKObjectUtilities.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitObjectMapping

@implementation RKPropertyInspector

+ (RKPropertyInspector *)sharedInspector
{
    static RKPropertyInspector *sharedInspector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInspector = [RKPropertyInspector new];
    });

    return sharedInspector;
}

- (id)init
{
    self = [super init];
    if (self) {
        _propertyNamesToTypesCache = [[NSCache alloc] init];
    }

    return self;
}

- (NSDictionary *)propertyNamesAndTypesForClass:(Class)theClass
{
    NSMutableDictionary *propertyNames = [_propertyNamesToTypesCache objectForKey:theClass];
    if (propertyNames) {
        return propertyNames;
    }
    propertyNames = [NSMutableDictionary dictionary];

    //include superclass properties
    Class currentClass = theClass;
    while (currentClass != nil) {
        // Get the raw list of properties
        unsigned int outCount = 0;
        objc_property_t *propList = class_copyPropertyList(currentClass, &outCount);

        // Collect the property names
        for (typeof(outCount) i = 0; i < outCount; i++) {
            objc_property_t *prop = propList + i;
            const char *propName = property_getName(*prop);

            if (strcmp(propName, "_mapkit_hasPanoramaID") != 0) {
                const char *attr = property_getAttributes(*prop);
                if (attr) {
                    Class aClass = RKKeyValueCodingClassFromPropertyAttributes(attr);
                    if (aClass) {
                        NSString *propNameObj = [[NSString alloc] initWithCString:propName encoding:NSUTF8StringEncoding];
                        if (propNameObj) {
                            [propertyNames setObject:aClass forKey:propNameObj];
                        }
                    }
                }
            }
        }

        free(propList);
        currentClass = [currentClass superclass];
    }

    [_propertyNamesToTypesCache setObject:propertyNames forKey:theClass];
    RKLogDebug(@"Cached property names and types for Class '%@': %@", NSStringFromClass(theClass), propertyNames);
    return propertyNames;
}

- (Class)classForPropertyNamed:(NSString *)propertyName ofClass:(Class)objectClass
{
    NSDictionary *dictionary = [self propertyNamesAndTypesForClass:objectClass];
    return [dictionary objectForKey:propertyName];
}

@end


@interface NSObject (RKPropertyInspection)
- (Class)rk_classForPropertyAtKeyPath:(NSString *)keyPath;
@end

@implementation NSObject (RKPropertyInspection)

- (Class)rk_classForPropertyAtKeyPath:(NSString *)keyPath
{
    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    Class propertyClass = [self class];
    for (NSString *property in components) {
        propertyClass = [[RKPropertyInspector sharedInspector] classForPropertyNamed:property ofClass:propertyClass];
        if (! propertyClass) break;
    }
    
    return propertyClass;
}

@end

Class RKPropertyInspectorGetClassForPropertyAtKeyPathOfObject(NSString *keyPath, id object)
{
    return [object rk_classForPropertyAtKeyPath:keyPath];
}
