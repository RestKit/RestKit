//
//  OTCat.h
//  OTRestFramework
//
//  Created by Jeremy Ellison on 1/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTHuman;

@interface OTCat : NSObject {

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

@property (nonatomic, retain) OTHuman * human;

@end
