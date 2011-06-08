//
//  RKTableViewDataSource.m
//  RestKit
//
//  Created by Blake Watters on 4/26/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKTableViewDataSource.h"
#import "RKMappableObjectTableItem.h"
#import "RKObjectLoaderTTModel.h"

@implementation RKTableViewDataSource

+ (id)dataSource {
    return [[self new] autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        _objectToTableCellMappings = [NSMutableDictionary new];
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
    
    [super dealloc];
}

- (NSArray*)modelObjects {
    return [(RKObjectLoaderTTModel*)self.model objects];
}

- (void)registerCellClass:(Class)cellCell forObjectClass:(Class)objectClass {
    [_objectToTableCellMappings setObject:cellCell forKey:objectClass];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.modelObjects count];
}

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object {
    RKMappableObjectTableItem* tableItem = (RKMappableObjectTableItem*)object;
    Class cellClass = [_objectToTableCellMappings objectForKey:[tableItem.object class]];
    NSAssert(cellClass != nil, @"Must have a registered cell class for type");
    return cellClass;
}

- (id)tableView:(UITableView*)tableView objectForRowAtIndexPath:(NSIndexPath*)indexPath {
    if (indexPath.row < [self.modelObjects count]) {
        NSObject* mappableObject =  [self.modelObjects objectAtIndex:indexPath.row];
        RKMappableObjectTableItem* tableItem = [RKMappableObjectTableItem itemWithObject:mappableObject];
        return tableItem;
    } else {
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

@end
