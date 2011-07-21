//
//  RKObjectMappingResult.h
//  RestKit
//
//  Created by Blake Watters on 5/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RKObjectMappingResult : NSObject {
    id _keyPathToMappedObjects;
}

- (id)initWithDictionary:(id)dictionary;
+ (RKObjectMappingResult*)mappingResultWithDictionary:(NSDictionary*)keyPathToMappedObjects;

/**
 Return the mapping result as a dictionary
 */
- (NSDictionary*)asDictionary;
- (id)asObject;
- (NSArray*)asCollection;
- (NSError*)asError;

@end
