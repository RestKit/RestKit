//
//  Human.h
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKManagedObject.h"

@class RKCat;

@interface RKHuman : RKManagedObject {	
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

@end

@interface RKHuman (CoreDataGeneratedAccessors)
- (void)addCatsObject:(RKCat *)value;
- (void)removeCatsObject:(RKCat *)value;
- (void)addCats:(NSSet *)value;
- (void)removeCats:(NSSet *)value;
@end