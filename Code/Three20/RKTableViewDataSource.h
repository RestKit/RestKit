//
//  RKTableViewDataSource.h
//  RestKit
//
//  Created by Blake Watters on 4/26/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import "../RestKit.h"

@interface RKTableViewDataSource : TTTableViewDataSource {
    NSMutableDictionary* _objectToTableCellMappings;
}

// The objects loaded via the RKObjectLoaderTTModel instance...
@property (nonatomic, readonly) NSArray* modelObjects;

+ (id)dataSource;
- (void)registerCellClass:(Class)cellCell forObjectClass:(Class)objectClass; // TODO: Better method name??

// TODO: Delegate?

@end
