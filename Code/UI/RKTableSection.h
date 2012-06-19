//
//  RKTableViewSection.h
//  RestKit
//
//  Created by Blake Watters on 8/2/11.
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

#import <UIKit/UIKit.h>
#import "RKObjectMapping.h"
#import "RKTableViewCellMappings.h"

@class RKTableController;

@interface RKTableSection : NSObject

// Basics
@property (nonatomic, assign)   RKTableController *tableController;
@property (nonatomic, readonly) UITableView *tableView;

// Object Mapping Table Stuff
@property (nonatomic, retain) NSArray *objects;
@property (nonatomic, retain) RKTableViewCellMappings *cellMappings;

// Header & Footer Views, etc.
@property (nonatomic, retain) NSString *headerTitle;
@property (nonatomic, retain) NSString *footerTitle;
@property (nonatomic, assign) CGFloat headerHeight;
@property (nonatomic, assign) CGFloat footerHeight;
@property (nonatomic, retain) UIView *headerView;
@property (nonatomic, retain) UIView *footerView;

// number of cells in the section
@property (nonatomic, readonly) NSUInteger rowCount;

+ (id)section;
+ (id)sectionUsingBlock:(void (^)(RKTableSection *))block;
+ (id)sectionForObjects:(NSArray *)objects withMappings:(RKTableViewCellMappings *)cellMappings;

- (id)objectAtIndex:(NSUInteger)rowIndex;
- (void)insertObject:(id)object atIndex:(NSUInteger)index;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object;
- (void)moveObjectAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex;

@end
