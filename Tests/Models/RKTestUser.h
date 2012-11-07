//
//  RKTestUser.h
//  RestKit
//
//  Created by Blake Watters on 8/5/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKTestAddress.h"

@interface RKTestUser : NSObject

@property (nonatomic, strong) NSNumber *userID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *birthDate;
@property (nonatomic, strong) NSDate *favoriteDate;
@property (nonatomic, strong) NSArray *favoriteColors;
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
@property (nonatomic, strong) NSOrderedSet *friendsOrderedSet;
@property (nonatomic, strong) NSData *data;

+ (RKTestUser *)user;

@end
