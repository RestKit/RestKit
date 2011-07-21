//
//  RootViewController.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource> {
    NSArray* _exampleTableItems;
}

@end
