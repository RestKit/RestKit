//
//  RKMappingOperationDataSource.h
//  RestKit
//
//  Created by Blake Watters on 7/3/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RKObjectMapping, RKMappingOperation;

// Data source for mapping operations
@protocol RKMappingOperationDataSource <NSObject>

@required
- (id)objectForMappableContent:(id)mappableContent mapping:(RKObjectMapping *)mapping;

@optional
- (void)commitChangesForMappingOperation:(RKMappingOperation *)mappingOperation;

@end
