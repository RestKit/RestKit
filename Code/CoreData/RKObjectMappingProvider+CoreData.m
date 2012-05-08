//
//  RKObjectMappingProvider+CoreData.m
//  RestKit
//
//  Created by Jeff Arena on 1/26/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKObjectMappingProvider+CoreData.h"
#import "RKOrderedDictionary.h"
#import "RKFixCategoryBug.h"
#import "RKPathMatcher.h"
#import <objc/runtime.h>


RK_FIX_CATEGORY_BUG(RKObjectMappingProvider_CoreData)
@implementation RKObjectMappingProvider (CoreData)

const NSString *RK_OBJECT_MAPPING_PROVIDER_IS_SIMPLE_BLOCK = @"RKObjectMappingProvider_IsSimpleBlock";
const NSString *RK_OBJECT_MAPPING_PROVIDER_RESOURCE_PATTERN = @"RKObjectMappingProvider_ResourcePattern";

- (void)setObjectMapping:(RKObjectMappingDefinition *)objectMapping forResourcePathPattern:(NSString *)resourcePath withFetchRequestBlock:(RKObjectMappingProviderFetchRequestBlock)fetchRequestBlock {
    [self setEntry:[RKObjectMappingProviderContextEntry contextEntryWithMapping:objectMapping
                                                                       userData:fetchRequestBlock] forResourcePathPattern:resourcePath];
}

- (void)setObjectMapping:(RKObjectMappingDefinition *)objectMapping forResourcePathPattern:(NSString *)resourcePath withSimpleFetchRequestBlock:(RKObjectMappingProviderSimpleFetchRequestBlock)fetchRequestBlock {
    objc_setAssociatedObject(fetchRequestBlock, RK_OBJECT_MAPPING_PROVIDER_IS_SIMPLE_BLOCK, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(fetchRequestBlock, RK_OBJECT_MAPPING_PROVIDER_RESOURCE_PATTERN, resourcePath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self setEntry:[RKObjectMappingProviderContextEntry contextEntryWithMapping:objectMapping userData:fetchRequestBlock] forResourcePathPattern:resourcePath];
}

- (NSFetchRequest *)fetchRequestForResourcePath:(NSString *)resourcePath {
    RKObjectMappingProviderContextEntry *entry = [self entryForResourcePath:resourcePath];
    if (entry.userData) {
        BOOL isSimpleBlock = [objc_getAssociatedObject(entry.userData, RK_OBJECT_MAPPING_PROVIDER_IS_SIMPLE_BLOCK) boolValue];
        if(isSimpleBlock) {
            NSFetchRequest *(^simpleFetchRequestBlock)(NSDictionary*) = entry.userData;
            NSString *resourcePattern = objc_getAssociatedObject(entry.userData, RK_OBJECT_MAPPING_PROVIDER_RESOURCE_PATTERN);
            NSDictionary *parsed = nil;
            RKPathMatcher *matcher = [RKPathMatcher matcherWithPath:resourcePath];
            [matcher matchesPattern:resourcePattern tokenizeQueryStrings:YES parsedArguments:&parsed];
            return simpleFetchRequestBlock(parsed);
        } else {
            NSFetchRequest *(^fetchRequestBlock)(NSString *) = entry.userData;
            return fetchRequestBlock(resourcePath);
        }
    }

    return nil;
}

@end
