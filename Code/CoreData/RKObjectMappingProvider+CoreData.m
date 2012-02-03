//
//  RKObjectMappingProvider+CoreData.m
//  RestKit
//
//  Created by Jeff Arena on 1/26/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKObjectMappingProvider+CoreData.h"
#import "RKOrderedDictionary.h"

@implementation RKObjectMappingProvider (CoreData)

- (void)setObjectMapping:(id<RKObjectMappingDefinition>)objectMapping forResourcePathPattern:(NSString *)resourcePath withFetchRequestBlock:(RKObjectMappingProviderFetchRequestBlock)fetchRequestBlock {
    [self setEntry:[RKObjectMappingProviderContextEntry contextEntryWithMapping:objectMapping
                                                                       userData:[fetchRequestBlock copy]] forResourcePathPattern:resourcePath];
}

@end
