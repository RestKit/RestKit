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

NSString * const RKPropertyInspectionNameKey = @"name";
NSString * const RKPropertyInspectionKeyValueCodingClassKey = @"keyValueCodingClass";
NSString * const RKPropertyInspectionIsPrimitiveKey = @"isPrimitive";


@implementation RKPropertyInspectorPropertyInfo

+ (instancetype)propertyInfoWithName:(NSString *)name keyValueClass:(Class)kvClass isPrimitive:(BOOL)isPrimitive
{
    return [[self alloc] initWithName:name keyValueClass:kvClass isPrimitive:isPrimitive];
}

- (instancetype)initWithName:(NSString *)name keyValueClass:(Class)kvClass isPrimitive:(BOOL)isPrimitive
{
    if (self = [super init]) {
        _name = [name copy];
        _keyValueCodingClass = kvClass;
        _isPrimitive = isPrimitive;
    }
    return self;
}

@end


@interface RKPropertyInspector ()
#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t queue;
#else
@property (nonatomic, assign) dispatch_queue_t queue;
#endif
@property (nonatomic, strong) NSMutableDictionary *inspectionCache;
@end

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

- (instancetype)init
{
    self = [super init];
    if (self) {
        // NOTE: We use an `NSMutableDictionary` because it is *much* faster than `NSCache` on lookup
        self.inspectionCache = [NSMutableDictionary dictionary];
        self.queue = dispatch_queue_create("org.restkit.core-data.property-inspection-queue", DISPATCH_QUEUE_CONCURRENT);
    }

    return self;
}

- (void)dealloc
{
#if !OS_OBJECT_USE_OBJC
    if (_queue) dispatch_release(_queue);
#endif
    _queue = NULL;
}

- (NSDictionary *)propertyInspectionForClass:(Class)objectClass
{
    __block NSMutableDictionary *inspection;
    dispatch_sync(self.queue, ^{
        inspection = (self.inspectionCache)[objectClass];
    });
    if (inspection) return inspection;
    
    inspection = [NSMutableDictionary dictionary];

    //include superclass properties
    Class currentClass = objectClass;
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
                        NSString *propNameString = [[NSString alloc] initWithCString:propName encoding:NSUTF8StringEncoding];
                        if (propNameString) {
                            BOOL isPrimitive = NO;
                            if (attr) {
                                const char *typeIdentifierLoc = strchr(attr, 'T');
                                if (typeIdentifierLoc) {
                                    isPrimitive = (typeIdentifierLoc[1] != '@');
                                }
                            }
                            
                            RKPropertyInspectorPropertyInfo *info;
                            info = [RKPropertyInspectorPropertyInfo propertyInfoWithName:propNameString
                                                                           keyValueClass:aClass
                                                                             isPrimitive:isPrimitive];
                            inspection[propNameString] = info;
                        }
                    }
                }
            }
        }

        free(propList);
        Class superclass = [currentClass superclass];
        Class nsManagedObject = NSClassFromString(@"NSManagedObject");
        currentClass = (superclass == [NSObject class] || (nsManagedObject && superclass == nsManagedObject)) ? nil : superclass;
    }

    /* dispatch_barrier_async is dangerous if we are called from +initialize */
    dispatch_barrier_sync(self.queue, ^{
        (self.inspectionCache)[(id<NSCopying>)objectClass] = inspection;
        RKLogDebug(@"Cached property inspection for Class '%@': %@", NSStringFromClass(objectClass), inspection);
    });
    return inspection;
}

- (Class)classForPropertyNamed:(NSString *)propertyName ofClass:(Class)objectClass isPrimitive:(BOOL *)isPrimitive
{
    NSDictionary *classInspection = [self propertyInspectionForClass:objectClass];
    RKPropertyInspectorPropertyInfo *propertyInspection = classInspection[propertyName];
    if (isPrimitive) *isPrimitive = propertyInspection.isPrimitive;
    return propertyInspection.keyValueCodingClass;
}

@end


@interface NSObject (RKPropertyInspection)
- (Class)rk_classForPropertyAtKeyPath:(NSString *)keyPath isPrimitive:(BOOL *)isPrimitive;
@end

@implementation NSObject (RKPropertyInspection)

- (Class)rk_classForPropertyAtKeyPath:(NSString *)keyPath isPrimitive:(BOOL *)isPrimitive
{
    NSRange dotRange = [keyPath rangeOfString:@"." options:NSLiteralSearch];
    RKPropertyInspector *inspector = [RKPropertyInspector sharedInspector];
    Class propertyClass = [self class];
    
    if (dotRange.length == 0) {
        return [inspector classForPropertyNamed:keyPath ofClass:propertyClass isPrimitive:isPrimitive];
    }

    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    for (NSString *property in components) {
        propertyClass = [inspector classForPropertyNamed:property ofClass:propertyClass isPrimitive:isPrimitive];
        if (! propertyClass) break;
    }
    
    return propertyClass;
}

@end

Class RKPropertyInspectorGetClassForPropertyAtKeyPathOfObject(NSString *keyPath, id object)
{
    return [object rk_classForPropertyAtKeyPath:keyPath isPrimitive:nil];
}

BOOL RKPropertyInspectorIsPropertyAtKeyPathOfObjectPrimitive(NSString *keyPath, id object)
{
    BOOL isPrimitive = NO;
    [object rk_classForPropertyAtKeyPath:keyPath isPrimitive:&isPrimitive];
    return isPrimitive;
}
