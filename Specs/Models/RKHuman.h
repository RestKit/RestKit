//
//  Human.h
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters
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
