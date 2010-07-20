//
//  RKCat.h
//  RestKit
//
//  Created by Jeremy Ellison on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKManagedObject.h"


@class RKHuman;

@interface RKCat : RKManagedObject {

}

@property (nonatomic, retain) NSNumber* age;
@property (nonatomic, retain) NSNumber* birthYear;
@property (nonatomic, retain) NSString* color;
@property (nonatomic, retain) NSDate* createdAt;
@property (nonatomic, retain) NSNumber* humanId;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* nickName;
@property (nonatomic, retain) NSNumber* railsID;
@property (nonatomic, retain) NSString* sex;
@property (nonatomic, retain) NSDate* updatedAt;

@property (nonatomic, retain) RKHuman * human;

@end
