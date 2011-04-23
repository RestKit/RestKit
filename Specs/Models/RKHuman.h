//
//  Human.h
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "NSManagedObject+ActiveRecord.h"

@class RKCat;

@interface RKHuman : NSManagedObject {	
}

@property (nonatomic, retain) NSNumber* railsID;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* nickName;
@property (nonatomic, retain) NSDate* birthday;
@property (nonatomic, retain) NSString* sex;
@property (nonatomic, retain) NSNumber* age;
@property (nonatomic, retain) NSDate* createdAt;
@property (nonatomic, retain) NSDate* updatedAt;

@property (nonatomic, retain) NSSet* cats;
@property (nonatomic, retain) RKCat* favoriteCat;

@end

@interface RKHuman (CoreDataGeneratedAccessors)
- (void)addCatsObject:(RKCat *)value;
- (void)removeCatsObject:(RKCat *)value;
- (void)addCats:(NSSet *)value;
- (void)removeCats:(NSSet *)value;

@end
