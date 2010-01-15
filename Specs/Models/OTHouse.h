//
//  OTHouse.h
//  OTRestFramework
//
//  Created by Jeremy Ellison on 1/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OTRestManagedModel.h"


@interface OTHouse : OTRestManagedModel {

}

@property (nonatomic, retain) NSString* city;
@property (nonatomic, retain) NSDate* createdAt;
@property (nonatomic, retain) NSNumber* ownerId;
@property (nonatomic, retain) NSNumber* railsID;
@property (nonatomic, retain) NSString* state;
@property (nonatomic, retain) NSString* street;
@property (nonatomic, retain) NSDate* updatedAt;
@property (nonatomic, retain) NSString* zip;

@end
