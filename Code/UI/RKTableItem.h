//
//  RKTableItem.h
//  RestKit
//
//  Created by Blake Watters on 8/8/11.
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
#import "RKMutableBlockDictionary.h"

@class RKTableViewCellMapping;

/**
 A generic class for defining vanilla table items when
 you do not have local domain items for your table rows. This
 is used to implement simple static tables quickly.
 */
@interface RKTableItem : NSObject

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *detailText;
@property (nonatomic, retain) UIImage  *image;
@property (nonatomic, retain) NSString *URL;

/**
 A dictionary reference for storing ad-hoc KVC data useful in building
 table items that require extra information beyond the concrete properties
 available on the table item.

 Values stored within the userData dictionary can be used to map arbitrary data
 into your table cells without resorting to subclassing RKTableItem:
    [tableItem.userData setValue:userAvatarImage forKey:@"userAvatarImage"];
    [tableItem.cellMapping mapKeyPath:@"userData.userAvatarImage" toKeyPath:@"imageView.image"];

 Note that this is an instance of RKMutableBlockDictionary -- a dictionary capable of
 storing executable block values that will be resolved at mapping time.

 For convenience, you can also perform key-value coding operations on instances of RKTableItem
 themselves. Any undefined KVC operations will be passed through to the underlying
 userData property. This permits you to have alignment on your keyPaths between the
 table item and your target cells when defining mappings. Considering the above examples,
 we could also write the following code instead:
     [tableItem setValue:userAvatarImage forKey:@"userAvatarImage"];
     [tableItem.cellMapping mapKeyPath:@"userAvatarImage" toKeyPath:@"imageView.image"];

 Or more concretely, if we have a group of properties such as title, description, and publishedDate
 on our UITableViewCell destination class, we can configure it quickly via:
    [tableItem setValue:@"Some Title" forKey:@"title"];
    [tableItem setValue:@"This is an awesome movie." forKey:@"description"];
    [tableItem setValue:[NSDate date] forKey:@"publishedDate"];
    [tableItem.cellMapping mapAttributes:@"title", @"description", @"publishedDate", nil];

 @see RKMutableBlockDictionary
 */
@property (nonatomic, retain) RKMutableBlockDictionary *userData;

/**
 Informal protocol implementation. Any object that responds to the `cellMapping` message
 and returns an RKTableViewCellMapping will be mapped into a table view cell according to
 the rules in the mapping.

 Generally table items are mapped using class -> cell mapping semantics. This is configured
 via invocation of [RKTableController mapObjectClass:toTableCellClass:]. Default mappings for
 RKTableItem instances are configured on your behalf when you invoke the [RKTableView loadTableItems:]
 family of methods.

 If you assign a cell mapping to an individual table item then the assigned cell mapping will
 be used instead of the class configured 'default' mapping.

 **Default**: nil
 */
@property (nonatomic, retain) RKTableViewCellMapping *cellMapping;

/**
 Return a new array of RKTableItem instances given a nil terminated list of strings.
 Each table item will have the text property set to the string provided.
 */
+ (NSArray *)tableItemsFromStrings:(NSString *)firstString, ... NS_REQUIRES_NIL_TERMINATION;

/**
 Returns a new table item
 */
+ (id)tableItem;

/**
 Initialize a new table item and yield it to the block for configuration
 */
+ (id)tableItemUsingBlock:(void (^)(RKTableItem *tableItem))block;

/**
 Initialize a new table item with the specified text
 */
+ (id)tableItemWithText:(NSString *)text;

/**
 Initialize a new table item with the specified text & details text
 */
+ (id)tableItemWithText:(NSString *)text detailText:(NSString *)detailText;

/**
 Construct a new auto-released table item with the specified text, detailText and image
 properties.
 */
+ (id)tableItemWithText:(NSString *)text detailText:(NSString *)detailText image:(UIImage *)image;

/**
 Construct a new table item with the specified text and yield it to the block for configuration.
 This is a convenient mechanism for quickly constructing table items that have been subclassed.

 For example:

    NSArray *tableItems = [NSArray arrayWithObjects:[MyTableItem tableItemWithText:@"Foo"
                                                                        usingBlock:^(RKTableItem *tableItem) {
                                                                            [(MyTableItem *)tableItem setURL:@"app://whatever"];
                                                                        }], ...];
 */
+ (id)tableItemWithText:(NSString *)text usingBlock:(void (^)(RKTableItem *tableItem))block;

/**
 Constructs a new table item with the specified text and URL. This is useful if you are working
 with Three20 or another library that provides URL dispatching.
 */
+ (id)tableItemWithText:(NSString *)text URL:(NSString *)URL;

/**
 Construct a new table item with the specified cell mapping
 */
+ (id)tableItemWithCellMapping:(RKTableViewCellMapping *)cellMapping;

/**
 Construct a new table item that will map into an instance of the specified
 UITableViewCell subclass. This is helpful if you are constructing a static table
 with a handful of different cells and don't need to configure a full cell mapping.

 When invoked, an instance of RKTableViewCellMapping will be created on your behalf
 and assigned to the cellMapping property. The objectClass of the cellMapping will be
 set to the subclass of UITableViewCell you provided.

 @param tableViewCellSubclass A subclass of UITableViewCell to map this item into
 */
+ (id)tableItemWithCellClass:(Class)tableViewCellSubclass;

@end
