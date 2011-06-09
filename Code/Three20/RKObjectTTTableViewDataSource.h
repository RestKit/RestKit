//
//  RKObjectTTTableViewDataSource.h
//  RestKit
//
//  Created by Blake Watters on 4/26/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import "../RestKit.h"

/**
 Provides a data source for interfacing RestKit object loaders with Three20
 Table Views. The dataSource is intended to be used with an instance of
 RKObjectLoaderTTModel to perform a remote load of objects. The data source
 then allows you to turn your loaded objects into Three20 table items without
 a bunch of intermediary code.
 
 @see RKObjectLoaderTTModel
 */
@interface RKObjectTTTableViewDataSource : TTTableViewDataSource {
    NSMutableDictionary* _objectToTableCellMappings;
    NSMutableDictionary* _objectClassToTableItemMappings;
}

/**
 The collection of model objects fetched from the remote system via
 the RKObjectLoaderTTModel instance set as the dataSource's model property
 */
@property (nonatomic, readonly) NSArray* modelObjects;

/**
 Returns a new auto-released data source
 */
+ (id)dataSource;

/**
 Registers a mapping from a class to a Three20 Table Item using an object mapping. The
 object mapping should target an instance of the Three20 Table Item classes.
 
 For example, consider that we want to create a simple TTTableTextItem with text and a URL:
     RKObjectTTTableViewDataSource* dataSource = [RKObjectTTTableViewDataSource dataSource];
     RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TTTableTextItem class]];
     [mapping mapKeyPath:@"name" toAttribute:@"text"];
     [mapping mapKeyPath:@"attributeWithURL" toAttribute:@"URL"];
     [dataSource mapObjectClass:[MyModel class] toTableItemWithMapping:mapping];
 */
- (void)mapObjectClass:(Class)objectClass toTableItemWithMapping:(RKObjectMapping*)mapping;

/**
 Registers a mapping from an object class to a custom UITableViewCell class. When the dataSource
 loads, any objects matching the class will be marshalled into a temporary Three20 table item
 and then passed to an instance of the specified UITableViewCell.
 
 This method is used to implement totally custom table cell within Three20 without having to create
 intermediary Table Items.
 
 @see RKMappableObjectTableItem
 */
- (void)mapObjectClass:(Class)objectClass toTableCellClass:(Class)cellClass;

@end
