//
//  Task.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKCatalog.h"
#import "User.h"

@interface Task : NSManagedObject {
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *taskID;
@property (nonatomic, retain) NSNumber *assignedUserID;
@property (nonatomic, retain) User *assignedUser;

@end
