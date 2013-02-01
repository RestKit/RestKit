//
//  RKPost.h
//  RestKit
//
//  Created by Blake Watters on 1/24/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface RKPost : NSManagedObject
@property (nonatomic, strong) NSSet *tags;
@end
