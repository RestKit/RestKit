//
//  Human.h
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <CoreData/CoreData.h>

@class RKCat, RKHouse, RKResident;

@interface RKHuman : NSManagedObject

@property (nonatomic, strong) NSNumber *railsID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSDate *birthday;
@property (nonatomic, strong) NSString *sex;
@property (nonatomic, strong) NSNumber *age;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, strong) NSArray *favoriteColors;
@property (nonatomic, strong) NSMutableSet *mutableFavoriteColors;

@property (nonatomic, strong) NSSet *cats;
@property (nonatomic, strong) NSNumber *favoriteCatID;
@property (nonatomic, strong) RKCat *favoriteCat;

@property (nonatomic, strong) NSArray *catIDs;
@property (nonatomic, strong) NSOrderedSet *catsInOrderByAge;

@property (nonatomic, strong) NSNumber *likesDogs;

@property (nonatomic, strong) RKHouse *house;
@property (nonatomic, strong) RKHuman *landlord;
@property (nonatomic, strong) NSSet *roommates;
@property (nonatomic, strong) NSSet *tenants;
@property (nonatomic, strong) RKHouse *residence;
@property (nonatomic, strong) NSOrderedSet *housesResidedAt;

@property (nonatomic, strong) NSSet *friends;
@property (nonatomic, strong) NSOrderedSet *friendsInTheOrderWeMet;
@property (nonatomic, strong) NSNumber *isHappy;
@property (nonatomic, strong) NSNumber *houseID;
@end

@interface RKHuman (CoreDataGeneratedAccessors)
- (void)addCatsObject:(RKCat *)value;
- (void)removeCatsObject:(RKCat *)value;
- (void)addCats:(NSSet *)value;
- (void)removeCats:(NSSet *)value;
@end
