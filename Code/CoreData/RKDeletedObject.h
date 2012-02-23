//
//  RKDeletedObject.h
//  RestKit
//
//  Created by Evan Cordell on 2/23/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "NSManagedObject+ActiveRecord.h"

@interface RKDeletedObject : NSManagedObject

@property (nonatomic, retain) NSDictionary *data;

@end
