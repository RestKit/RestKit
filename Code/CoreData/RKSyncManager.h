//
//  RKSyncManager.h
//  RestKit
//
//  Created by Evan Cordell on 2/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    RKSyncStatusNone,
    RKSyncStatusPost,
    RKSyncStatusPut,
    RKSyncStatusDelete
} RKSyncStatus;

@interface RKSyncManager : NSObject

@end
