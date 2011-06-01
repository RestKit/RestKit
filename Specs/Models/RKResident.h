//
//  RKResident.h
//  RestKit
//
//  Created by Jeremy Ellison on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <CoreData/CoreData.h>

@class RKHouse;

@interface RKResident : NSManagedObject {
}

@property (nonatomic, retain) NSString* residableType;
@property (nonatomic, retain) NSNumber* railsID;
@property (nonatomic, retain) NSNumber* residableId;
@property (nonatomic, retain) NSNumber* houseId;
@property (nonatomic, retain) RKHouse* house;

@end
