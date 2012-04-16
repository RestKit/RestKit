//
//  RKObjectMappingProviderContextEntry.h
//  RestKit
//
//  Created by Jeff Arena on 1/26/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKObjectMappingDefinition.h"

@interface RKObjectMappingProviderContextEntry : NSObject

+ (RKObjectMappingProviderContextEntry *)contextEntryWithMapping:(RKObjectMappingDefinition *)mapping;
+ (RKObjectMappingProviderContextEntry *)contextEntryWithMapping:(RKObjectMappingDefinition *)mapping userData:(id)userData;

@property (nonatomic, retain) RKObjectMappingDefinition *mapping;
@property (nonatomic, retain) id userData;

@end
