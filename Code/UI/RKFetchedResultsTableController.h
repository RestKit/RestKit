//
//  RKFetchedResultsTableController.h
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

#import "RKAbstractTableController.h"

typedef UIView *(^RKFetchedResultsTableViewViewForHeaderInSectionBlock)(NSUInteger sectionIndex, NSString *sectionTitle);

@class RKFetchedResultsTableController;
@protocol RKFetchedResultsTableControllerDelegate <RKAbstractTableControllerDelegate>

@optional

// Sections
- (void)tableController:(RKFetchedResultsTableController *)tableController didInsertSectionAtIndex:(NSUInteger)sectionIndex;
- (void)tableController:(RKFetchedResultsTableController *)tableController didDeleteSectionAtIndex:(NSUInteger)sectionIndex;

@end

/**
 Instances of RKFetchedResultsTableController provide an interface for driving a UITableView
 */
@interface RKFetchedResultsTableController : RKAbstractTableController <NSFetchedResultsControllerDelegate> {
@private
    NSArray *_arraySortedFetchedObjects;
    BOOL _isEmptyBeforeAnimation;
}

@property (nonatomic, assign) id<RKFetchedResultsTableControllerDelegate> delegate;
@property (nonatomic, retain, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, copy) NSString *resourcePath;
@property (nonatomic, retain) NSFetchRequest *fetchRequest;
@property (nonatomic, assign) CGFloat heightForHeaderInSection;
@property (nonatomic, copy) RKFetchedResultsTableViewViewForHeaderInSectionBlock onViewForHeaderInSection;
@property (nonatomic, retain) NSPredicate *predicate;
@property (nonatomic, retain) NSArray *sortDescriptors;
@property (nonatomic, copy) NSString *sectionNameKeyPath;
@property (nonatomic, copy) NSString *cacheName;
@property (nonatomic, assign) BOOL showsSectionIndexTitles;
@property (nonatomic, assign) SEL sortSelector;
@property (nonatomic, copy) NSComparator sortComparator;

- (void)setObjectMappingForClass:(Class)objectClass;
- (void)loadTable;
- (void)loadTableFromNetwork;
- (NSIndexPath *)indexPathForObject:(id)object;

@end
