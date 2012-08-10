//
//  Project.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKCatalog.h"
#import "User.h"

@interface Project : NSObject {
    NSNumber *_projectID;
    NSString *_name;
    NSString *_description;
    User *_user;
    NSArray *_tasks;
}

@property (nonatomic, retain) NSNumber *projectID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) NSArray *tasks;

@end
