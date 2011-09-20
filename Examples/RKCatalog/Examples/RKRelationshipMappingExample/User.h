//
//  User.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKCatalog.h"

@interface User : NSManagedObject {
}

@property (nonatomic, retain) NSNumber* userID;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* email;
@property (nonatomic, retain) NSSet* tasks;

@end
