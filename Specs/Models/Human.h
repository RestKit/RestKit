//
//  Human.h
//  OTRestFramework
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Objective 3. All rights reserved.
//

#import "OTRestManagedModel.h"


@interface Human : OTRestManagedModel {	
}

@property (nonatomic, retain) NSNumber* railsID;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* nickName;
@property (nonatomic, retain) NSDate* birthday;
@property (nonatomic, retain) NSString* sex;
@property (nonatomic, retain) NSNumber* age;
@property (nonatomic, retain) NSDate* createdAt;
@property (nonatomic, retain) NSDate* updatedAt;

@end
