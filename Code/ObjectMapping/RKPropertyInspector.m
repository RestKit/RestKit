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


+ (NSString *)propertyTypeFromAttributeString:(NSString *)attributeString
{
    NSString *type = [NSString string];
    NSScanner *typeScanner = [NSScanner scannerWithString:attributeString];
    [typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"@"] intoString:NULL];

    // we are not dealing with an object
    if ([typeScanner isAtEnd]) {
        return @"NULL";
    }
    [typeScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"@"] intoString:NULL];
    // this gets the actual object type
    [typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&type];
    return type;
}

+ (Class)kvcClassForObjCType:(const char *)type
{
    if (type) {
        // https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
        switch (type[0]) {
            case '@': {
                char *openingQuoteLoc = strchr(type, '"');
                if (openingQuoteLoc) {
                    char *closingQuoteLoc = strchr(openingQuoteLoc+1, '"');
                    if (closingQuoteLoc) {
                        size_t classNameStrLen = closingQuoteLoc-openingQuoteLoc;
                        char className[classNameStrLen];
                        memcpy(className, openingQuoteLoc+1, classNameStrLen-1);
                        // Null-terminate the array to stringify
                        className[classNameStrLen-1] = '\0';
                        return objc_getClass(className);
                    }
                }
                // If there is no quoted class type (id), it can be used as-is.
                return Nil;
            }
                
            case 'c': // char
            case 'C': // unsigned char
            case 's': // short
            case 'S': // unsigned short
            case 'i': // int
            case 'I': // unsigned int
            case 'l': // long
            case 'L': // unsigned long
            case 'q': // long long
            case 'Q': // unsigned long long
            case 'f': // float
            case 'd': // double
                return [NSNumber class];
                
            case 'B': // C++ bool or C99 _Bool
                return objc_getClass("NSCFBoolean")
                ?: objc_getClass("__NSCFBoolean")
                ?: [NSNumber class];
                
            case '{': // struct
            case 'b': // bitfield
            case '(': // union
                return [NSValue class];
                
            case '[': // c array
            case '^': // pointer
            case 'v': // void
            case '*': // char *
            case '#': // Class
            case ':': // selector
            case '?': // unknown type (function pointer, etc)
            default:
                break;
        }
    }
    return Nil;
}

+ (Class)kvcClassFromPropertyAttributes:(const char *)attr
{
    if (attr) {
        const char *typeIdentifierLoc = strchr(attr, 'T');
        if (typeIdentifierLoc) {
            return [self kvcClassForObjCType:(typeIdentifierLoc+1)];
        }
    }
    return Nil;
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
                    Class aClass = [RKPropertyInspector kvcClassFromPropertyAttributes:attr];
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

- (Class)typeForProperty:(NSString *)propertyName ofClass:(Class)objectClass
{
    NSDictionary *dictionary = [self propertyNamesAndTypesForClass:objectClass];
    return [dictionary objectForKey:propertyName];
}

@end
