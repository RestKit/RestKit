//
//  DetailViewController.h
//  RKTableViewExample
//
//  Created by Blake Watters on 8/2/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
