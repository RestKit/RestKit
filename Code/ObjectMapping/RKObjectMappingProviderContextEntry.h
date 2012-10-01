//
//  RKObjectMappingProviderContextEntry.h
//  RestKit
//
//  Created by Jeff Arena on 1/26/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKMapping.h"

@interface RKObjectMappingProviderContextEntry : NSObject

+ (RKObjectMappingProviderContextEntry *)contextEntryWithMapping:(RKMapping *)mapping;
+ (RKObjectMappingProviderContextEntry *)contextEntryWithMapping:(RKMapping *)mapping userData:(id)userData;

@property (nonatomic, retain) RKMapping *mapping;
@property (nonatomic, retain) id userData;

@end
