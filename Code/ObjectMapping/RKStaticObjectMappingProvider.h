//
//  RKStaticObjectMappingProvider.h
//  RestKit
//
//  Created by Jeremy Ellison on 5/6/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapper.h"


@interface RKStaticObjectMappingProvider : NSObject <RKObjectMappingProvider> {
    NSMutableDictionary* _mappings;
}

- (void)setMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath;

@end
