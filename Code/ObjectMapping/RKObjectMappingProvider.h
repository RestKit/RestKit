//
//  RKObjectMappingProvider.h
//  RestKit
//
//  Created by Jeremy Ellison on 5/6/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMapping.h"

/*!
 Responsible for providing object mappings to an instance of the object mapper
 by evaluating the current keyPath being operated on
 */
@interface RKObjectMappingProvider : NSObject {
    NSMutableDictionary* _mappings;
}

- (void)setMapping:(RKObjectMapping*)mapping forKeyPath:(NSString*)keyPath;
- (NSDictionary*)objectMappingsByKeyPath;

@end
