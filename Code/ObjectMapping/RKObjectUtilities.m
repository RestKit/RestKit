//
//  RKObjectUtilities.m
//  RestKit
//
//  Created by Blake Watters on 9/30/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import <objc/message.h>
#import <objc/runtime.h>
#import "RKObjectUtilities.h"
#import "RKBooleanClass.h"

BOOL RKObjectIsEqualToObject(id object, id anotherObject) {
    NSCAssert(object, @"Expected object not to be nil");
    NSCAssert(anotherObject, @"Expected anotherObject not to be nil");
    
    return (object == anotherObject) || [object isEqual:anotherObject];
}

BOOL RKClassIsCollection(Class aClass)
{
    return (aClass && ([aClass isSubclassOfClass:[NSSet class]] ||
                       [aClass isSubclassOfClass:[NSArray class]] ||
                       [aClass isSubclassOfClass:[NSOrderedSet class]]));
}

BOOL RKObjectIsCollection(id object)
{
    return RKClassIsCollection([object class]);
}

BOOL RKObjectIsCollectionContainingOnlyManagedObjects(id object)
{
    if (! RKObjectIsCollection(object)) return NO;
    Class managedObjectClass = NSClassFromString(@"NSManagedObject");
    if (! managedObjectClass) return NO;
    for (id instance in object) {
        if (! [instance isKindOfClass:managedObjectClass]) return NO;
    }
    return YES;
}

BOOL RKObjectIsCollectionOfCollections(id object)
{
    if (! RKObjectIsCollection(object)) return NO;
    id collectionSanityCheckObject = nil;
    if ([object respondsToSelector:@selector(anyObject)]) collectionSanityCheckObject = [object anyObject];
    if ([object respondsToSelector:@selector(lastObject)]) collectionSanityCheckObject = [object lastObject];
    return RKObjectIsCollection(collectionSanityCheckObject);
}

Class RKKeyValueCodingClassForObjCType(const char *type)
{
    if (type) {
        switch (type[0]) {
            case _C_ID: {
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

            case _C_CHR: // char
            case _C_UCHR: // unsigned char
            case _C_SHT: // short
            case _C_USHT: // unsigned short
            case _C_INT: // int
            case _C_UINT: // unsigned int
            case _C_LNG: // long
            case _C_ULNG: // unsigned long
            case _C_LNG_LNG: // long long
            case _C_ULNG_LNG: // unsigned long long
            case _C_FLT: // float
            case _C_DBL: // double
                return [NSNumber class];
                
            case _C_BOOL: // C++ bool or C99 _Bool
                return RK_BOOLEAN_CLASS;
                
            case _C_STRUCT_B: // struct
            case _C_BFLD: // bitfield
            case _C_UNION_B: // union
                return [NSValue class];
                
            case _C_ARY_B: // c array
            case _C_PTR: // pointer
            case _C_VOID: // void
            case _C_CHARPTR: // char *
            case _C_CLASS: // Class
            case _C_SEL: // selector
            case _C_UNDEF: // unknown type (function pointer, etc)
            default:
                break;
        }
    }
    return Nil;
}

Class RKKeyValueCodingClassFromPropertyAttributes(const char *attr)
{
    if (attr) {
        const char *typeIdentifierLoc = strchr(attr, 'T');
        if (typeIdentifierLoc) {
            return RKKeyValueCodingClassForObjCType(typeIdentifierLoc+1);
        }
    }
    return Nil;
}

NSString *RKPropertyTypeFromAttributeString(NSString *attributeString)
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
