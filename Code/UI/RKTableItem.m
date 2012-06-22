//
//  RKTableItem.m
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

#import "RKTableItem.h"
#import "RKTableViewCellMapping.h"

@implementation RKTableItem

@synthesize text = _text;
@synthesize detailText = _detailText;
@synthesize image = _image;
@synthesize cellMapping = _cellMapping;
@synthesize URL = _URL;
@synthesize userData = _userData;

+ (NSArray *)tableItemsFromStrings:(NSString *)firstString, ...
{
    va_list args;
    va_start(args, firstString);
    NSMutableArray *tableItems = [NSMutableArray array];
    for (NSString *string = firstString; string != nil; string = va_arg(args, NSString *)) {
        RKTableItem *tableItem = [RKTableItem new];
        tableItem.text = string;
        [tableItems addObject:tableItem];
        [tableItem release];
    }
    va_end(args);

    return [NSArray arrayWithArray:tableItems];
}

+ (id)tableItem
{
    return [[self new] autorelease];
}

+ (id)tableItemUsingBlock:(void (^)(RKTableItem *))block
{
    RKTableItem *tableItem = [self tableItem];
    block(tableItem);
    return tableItem;
}

+ (id)tableItemWithText:(NSString *)text
{
    return [self tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = text;
    }];
}

+ (id)tableItemWithText:(NSString *)text detailText:(NSString *)detailText
{
    return [self tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = text;
        tableItem.detailText = detailText;
    }];
}

+ (id)tableItemWithText:(NSString *)text detailText:(NSString *)detailText image:(UIImage *)image
{
    RKTableItem *tableItem = [self new];
    tableItem.text = text;
    tableItem.detailText = detailText;
    tableItem.image = image;

    return [tableItem autorelease];
}

+ (id)tableItemWithText:(NSString *)text usingBlock:(void (^)(RKTableItem *))block
{
    RKTableItem *tableItem = [[self new] autorelease];
    tableItem.text = text;
    block(tableItem);
    return tableItem;
}

+ (id)tableItemWithText:(NSString *)text URL:(NSString *)URL
{
    RKTableItem *tableItem = [self tableItem];
    tableItem.text = text;
    tableItem.URL = URL;
    return tableItem;
}

+ (id)tableItemWithCellMapping:(RKTableViewCellMapping *)cellMapping
{
    RKTableItem *tableItem = [self tableItem];
    tableItem.cellMapping = cellMapping;

    return tableItem;
}

+ (id)tableItemWithCellClass:(Class)tableViewCellSubclass
{
    RKTableItem *tableItem = [self tableItem];
    tableItem.cellMapping = [RKTableViewCellMapping cellMapping];
    tableItem.cellMapping.cellClass = tableViewCellSubclass;

    return tableItem;
}

- (id)init
{
    self = [super init];
    if (self) {
        _userData = [RKMutableBlockDictionary new];
        _cellMapping = [RKTableViewCellMapping new];
    }

    return self;
}

- (void)dealloc
{
    [_text release];
    [_detailText release];
    [_image release];
    [_cellMapping release];
    [_userData release];

    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p text=%@, detailText=%@, image=%p>", NSStringFromClass([self class]), self, self.text, self.detailText, self.image];
}

#pragma mark - User Data KVC Proxy

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    [self.userData setValue:value ? value : [NSNull null] forKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return [self.userData valueForKey:key];
}

@end
