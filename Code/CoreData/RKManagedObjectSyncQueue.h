//
//  RKManagedObjectSyncQueue.h
//  RestKit
//
//  Created by Evan Cordell on 2/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NSManagedObject+ActiveRecord.h"

@interface RKManagedObjectSyncQueue : NSManagedObject

@property (nonatomic, retain) NSNumber * queuePosition;
@property (nonatomic, retain) NSNumber * syncStatus;
@property (nonatomic, retain) NSString * objectIDString;

@end
