//
//  UDTableView.h
//  tets
//
//  Created by Rolandas Razma on 12/3/11.
//  Copyright (c) 2011 UD7. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UDTableView : UITableView

// Stupid iOS5-
@property(nonatomic) BOOL allowsMultipleSelectionDuringEditing;
@property(nonatomic) BOOL allowsMultipleSelection;

@end
