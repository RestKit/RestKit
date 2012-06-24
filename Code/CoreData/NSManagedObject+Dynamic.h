//
//  NSManagedObject+Dynamic.h
//  RestKit
//
//  Created by Evan Cordell on 6/23/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "JRSwizzle.h"
#import "NSString+RKAdditions.h"

@interface NSManagedObject (Dynamic)

+ (NSManagedObject *)find:(NSDictionary *)params;
+ (NSArray *)findAll:(NSDictionary *)params;

@end
