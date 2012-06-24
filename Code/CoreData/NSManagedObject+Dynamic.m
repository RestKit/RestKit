//
//  NSManagedObject+Dynamic.m
//  RestKit
//
//  Created by Evan Cordell on 6/23/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "NSManagedObject+Dynamic.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKFixCategoryBug.h"
#import "RKLog.h"

static id dynamicFindBy(id self, SEL _cmd, NSString *string);
static id dynamicFindAllBy(id self, SEL _cmd, NSString *string);

RK_FIX_CATEGORY_BUG(NSManagedObject_Dynamic)

@implementation NSManagedObject (Dynamic)

+ (BOOL) swizzledResolveClassMethod:(SEL)aSEL
{
    Class selfMetaClass = objc_getMetaClass([NSStringFromClass([self class]) UTF8String]);
    NSString *methodName = [NSString stringWithUTF8String:sel_getName(aSEL)];
    
    if ([methodName hasPrefix:@"findBy"]) {
        class_addMethod(selfMetaClass, sel_registerName([methodName UTF8String]), (IMP) dynamicFindBy, "@@:@");
        return YES;
    } else if ([methodName hasPrefix:@"findAllBy"]) {
        class_addMethod(selfMetaClass, sel_registerName([methodName UTF8String]), (IMP) dynamicFindAllBy, "@@:@");
        return YES;
    }
    
    //Double swizzle might not be necessary, since I *believe* resolveClassMethod is only called if a selector isn't found. But it doesn't seem to hurt anything (maybe perfomance?)
    NSError *error = nil;
    [selfMetaClass jr_swizzleClassMethod:@selector(resolveClassMethod:) withClassMethod:@selector(swizzledResolveClassMethod:) error:&error];
    BOOL result = [selfMetaClass resolveClassMethod:aSEL];
    [selfMetaClass jr_swizzleClassMethod:@selector(resolveClassMethod:) withClassMethod:@selector(swizzledResolveClassMethod:) error:&error];
    
    if (error) {
        RKLogError(@"Error swizzling resolveClassMethod: %@", error);
    }
    
    return result;
}

//+ (id)where:(NSString *)predicateString {
//    [self findAllWithPredicate:[NSPredicate predicateWith
//}

+ (NSManagedObject *)find:(NSDictionary *)params {
    //TODO: check for nil dictionary?
    //check for existence of properties? Return nil and log error if invalid? 
    NSString *query = @"";
    NSString *atSign = [NSString stringWithUTF8String:"@"];
    NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:[params count]]; 
    for (NSString *propertyName in params) {
        id propertyValue = [params objectForKey:propertyName];
        if (![query isEqualToString:@""]) {
            query = [query stringByAppendingString:@" AND "];
        }
        query = [query stringByAppendingString:[NSString stringWithFormat:@"%@ == %%%@", propertyName, atSign]];
        [arguments addObject:propertyValue];
    }
    return [self findFirstWithPredicate:[NSPredicate predicateWithFormat:query argumentArray:arguments]];
}

+ (NSArray *)findAll:(NSDictionary *)params {
    //TODO: check for nil dictionary?
    NSString *query = @"";
    NSString *atSign = [NSString stringWithUTF8String:"@"];
    NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:[params count]]; 

    for (NSString *propertyName in params) {
        id propertyValue = [params objectForKey:propertyName];
        if (![query isEqualToString:@""]) {
            query = [query stringByAppendingString:@" AND "];
        }
        query = [query stringByAppendingString:[NSString stringWithFormat:@"%@ == %%%@", propertyName, atSign]];
        [arguments addObject:propertyValue];
    }
    return [self findAllWithPredicate:[NSPredicate predicateWithFormat:query argumentArray:arguments]];
}

@end

static id dynamicFindBy(id self, SEL _cmd, NSString *string) {
    
    NSString *methodName = [NSString stringWithUTF8String:sel_getName(_cmd)];
    NSRange range = NSMakeRange(6, [methodName length] - 7);
    NSString *propertyName = [[methodName substringWithRange:range] stringByLowercasingFirstLetter];
    
    if (class_getProperty([self class], [propertyName UTF8String]) == NULL) {
        return nil;
    }
    
    return [self find:[NSDictionary dictionaryWithObjectsAndKeys: string, propertyName, nil]];
}      

static id dynamicFindAllBy(id self, SEL _cmd, NSString *string) {
    
    NSString *methodName = [NSString stringWithUTF8String:sel_getName(_cmd)];
    NSRange range = NSMakeRange(9, [methodName length] - 10);
    NSString *propertyName = [[methodName substringWithRange:range] stringByLowercasingFirstLetter];
    
    if (class_getProperty([self class], [propertyName UTF8String]) == NULL) {
        return nil;
    }
    
    return [self findAll:[NSDictionary dictionaryWithObjectsAndKeys:string, propertyName, nil]];
}
