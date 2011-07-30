//
//  RKObjectTTTableViewDataSource.m
//  RestKit
//
//  Created by Blake Watters on 4/26/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectTTTableViewDataSource.h"
#import "RKMappableObjectTableItem.h"
#import "RKObjectLoaderTTModel.h"
#import "RKLog.h"

@implementation RKObjectTTTableViewDataSource

+ (id)dataSource {
    return [[self new] autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        _objectToTableCellMappings = [NSMutableDictionary new];
        _objectClassToTableItemMappings = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)setModel:(id<TTModel>)model {
    if (NO == [model isKindOfClass:[RKObjectLoaderTTModel class]]) {
        [NSException raise:nil format:@"RKTableViewDataSource is designed to work with RestKit TTModel implementations only"];
    }
    
    [super setModel:model];
}

- (void)dealloc {
    [_objectToTableCellMappings release];
    [_objectClassToTableItemMappings release];
    
    [super dealloc];
}

- (NSArray*)modelObjects {
    return [(RKObjectLoaderTTModel*)self.model objects];
}

- (void)mapObjectClass:(Class)objectClass toTableCellClass:(Class)cellClass {
    [_objectToTableCellMappings setObject:cellClass forKey:objectClass];
}

- (void)mapObjectClass:(Class)objectClass toTableItemWithMapping:(RKObjectMapping*)mapping {
    [_objectClassToTableItemMappings setObject:mapping forKey:objectClass];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.modelObjects count];
}

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object {
    if ([object isKindOfClass:[RKMappableObjectTableItem class]]) {
        RKMappableObjectTableItem* tableItem = (RKMappableObjectTableItem*)object;
        Class cellClass = [_objectToTableCellMappings objectForKey:[tableItem.object class]];
        return cellClass;
    }
    
    return [super tableView:tableView cellClassForObject:object];
}

// Return the table item...
- (id)tableView:(UITableView*)tableView objectForRowAtIndexPath:(NSIndexPath*)indexPath {
    NSObject* mappableObject =  [self.modelObjects objectAtIndex:indexPath.row];
    
    if (indexPath.row < [self.modelObjects count]) {
        // See if we have a TableItem mapping for this class
        RKObjectMapping* mapping = [_objectClassToTableItemMappings objectForKey:[mappableObject class]];
        if (mapping) {
            NSError* error = nil;
            TTTableItem* tableItem = [[mapping.objectClass new] autorelease];
            RKObjectMappingOperation* operation = [RKObjectMappingOperation mappingOperationFromObject:mappableObject toObject:tableItem withMapping:mapping];
            BOOL success = [operation performMapping:&error];
            if (success) {
                return tableItem;
            } else {
                RKLogError(@"Unable to map object to table item: %@", error);
            }
        }
        
        // Otherwise enclose the object in a mappable table item
        return [RKMappableObjectTableItem itemWithObject:mappableObject];
    } else {
        // TODO: Log a warning
        return nil;
    }
}

- (NSIndexPath*)tableView:(UITableView*)tableView indexPathForObject:(id)object {
    NSUInteger objectIndex = [self.modelObjects indexOfObject:object];
    if (objectIndex != NSNotFound) {
        return [NSIndexPath indexPathForRow:objectIndex inSection:0];
    }
    return nil;
}

- (NSString*)titleForEmpty {
    return @"Empty!";
}

- (void)tableViewDidLoadModel:(UITableView*)tableView {
    // Model finished load. This should be an RKObjectLoaderTTModel...
}

@end
