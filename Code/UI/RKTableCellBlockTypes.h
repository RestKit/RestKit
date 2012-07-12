//
//  RKTableCellBlockTypes.h
//  RestKit
//
//  Created by Blake Watters on 6/6/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

typedef NSIndexPath *(^RKTableTargetIndexPathForMoveBlock)(UITableViewCell *cell, id object, NSIndexPath *sourceIndexPath, NSIndexPath *destIndexPath);
typedef UITableViewCellEditingStyle(^RKTableCellEditingStyleForObjectAtIndexPathBlock)(UITableViewCell *cell, id object, NSIndexPath *indexPath);
typedef NSString *(^RKTableStringForObjectAtIndexPathBlock)(UITableViewCell *cell, id object, NSIndexPath *indexPath);
typedef CGFloat(^RKTableHeightOfCellForObjectAtIndexPathBlock)(id object, NSIndexPath *indexPath);
typedef void(^RKTableVoidBlock)();
typedef void(^RKTableCellBlock)(UITableViewCell *cell);
typedef void(^RKTableCellForObjectAtIndexPathBlock)(UITableViewCell *cell, id object, NSIndexPath *indexPath);
