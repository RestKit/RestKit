//
//  RKObjectMappingProviderContextEntry.h
//  RestKit
//
//  Created by Jeff Arena on 1/26/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKObjectMappingDefinition.h"

@interface RKObjectMappingProviderContextEntry : NSObject

+ (RKObjectMappingProviderContextEntry *)contextEntryWithMapping:(id<RKObjectMappingDefinition>)mapping;
+ (RKObjectMappingProviderContextEntry *)contextEntryWithMapping:(id<RKObjectMappingDefinition>)mapping userData:(id)userData;

@property (nonatomic, retain) id<RKObjectMappingDefinition> mapping;
@property (nonatomic, retain) id userData;

@end
