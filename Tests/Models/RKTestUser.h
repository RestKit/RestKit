//
//  RKTestUser.h
//  RestKit
//
//  Created by Blake Watters on 8/5/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKTestAddress.h"
#import "RKHuman.h"

@interface RKTestCoordinate : NSObject
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@end

@interface RKTestUser : NSObject

@property (nonatomic, strong) NSNumber *userID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *emailAddress;
@property (nonatomic, strong) NSDate *birthDate;
@property (nonatomic, strong) NSDate *favoriteDate;
@property (nonatomic, strong) NSArray *favoriteColors;
@property (nonatomic, strong) NSMutableArray *mutableFavoriteColors;
@property (nonatomic, strong) NSDictionary *addressDictionary;
@property (nonatomic, strong) NSURL *website;
@property (nonatomic, strong) NSNumber *isDeveloper;
@property (nonatomic, strong) NSNumber *luckyNumber;
@property (nonatomic, strong) NSDecimalNumber *weight;
@property (nonatomic, strong) NSArray *interests;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) RKTestAddress *address;
@property (nonatomic, strong) NSArray *friends;
@property (nonatomic, strong) NSSet *friendsSet;
@property (nonatomic, strong) RKHuman *bestFriend;
@property (nonatomic, strong) NSOrderedSet *friendsOrderedSet;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) RKTestCoordinate *coordinate;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, assign) NSInteger position;
@property (nonatomic, strong) RKTestUser *friend;

+ (RKTestUser *)user;

@end
