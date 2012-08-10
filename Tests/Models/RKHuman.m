//
//  Human.m
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


#import "RKHuman.h"
#import "NSDictionary+RKAdditions.h"

@implementation RKHuman

@dynamic railsID;
@dynamic name;
@dynamic nickName;
@dynamic birthday;
@dynamic sex;
@dynamic age;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic favoriteColors;

@dynamic favoriteCat;
@dynamic cats;
@dynamic catIDs;
@dynamic catsInOrderByAge;

- (NSString *)polymorphicResourcePath
{
    return @"/this/is/the/path";
}

@end
