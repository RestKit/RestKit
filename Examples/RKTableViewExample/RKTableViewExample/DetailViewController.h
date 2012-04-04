//
//  DetailViewController.h
//  RKTableViewExample
//
//  Created by Blake Watters on 8/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
