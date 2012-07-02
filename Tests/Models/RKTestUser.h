//
//  RKTestUser.h
//  RestKit
//
//  Created by Blake Watters on 8/5/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKTestAddress.h"

@interface RKTestUser : NSObject {
    NSNumber *_userID;
    NSString *_name;
    NSDate *_birthDate;
    NSArray *_favoriteColors;
    NSDictionary *_addressDictionary;
    NSURL *_website;
    NSNumber *_isDeveloper;
    NSNumber *_luckyNumber;
    NSDecimalNumber *_weight;
    NSArray *_interests;
    NSString *_country;

    // Relationships
    RKTestAddress *_address;
    NSArray *_friends;
}

@property (nonatomic, retain) NSNumber *userID;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSDate *birthDate;
@property (nonatomic, retain) NSDate *favoriteDate;
@property (nonatomic, retain) NSArray *favoriteColors;
@property (nonatomic, retain) NSDictionary *addressDictionary;
@property (nonatomic, retain) NSURL *website;
@property (nonatomic, retain) NSNumber *isDeveloper;
@property (nonatomic, retain) NSNumber *luckyNumber;
@property (nonatomic, retain) NSDecimalNumber *weight;
@property (nonatomic, retain) NSArray *interests;
@property (nonatomic, retain) NSString *country;
@property (nonatomic, retain) RKTestAddress *address;
@property (nonatomic, retain) NSArray *friends;
@property (nonatomic, retain) NSSet *friendsSet;
@property (nonatomic, retain) NSOrderedSet *friendsOrderedSet;

+ (RKTestUser *)user;

@end
