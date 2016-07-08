//
//  RKTwitterViewController.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTwitterViewController.h"
#import "RKTweet.h"

@interface RKTwitterViewController (Private)
- (void)loadData;
@end

@implementation RKTwitterViewController

- (void)loadTimeline
{
    // Load the object model via RestKit
    RKObjectManager *objectManager = [RKObjectManager sharedManager];

    [objectManager getObjectsAtPath:@"/status/user_timeline/RestKit"
                         parameters:nil
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                              NSArray* statuses = [mappingResult array];
                              NSLog(@"Loaded statuses: %@", statuses);
                              _statuses = statuses;
                              if(self.isViewLoaded)
                                [_tableView reloadData];
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                              UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                               message:[error localizedDescription]
                                                                              delegate:nil
                                                                     cancelButtonTitle:@"OK"
                                                                     otherButtonTitles:nil];
                              [alert show];
                              NSLog(@"Hit error: %@", error);
                            }];
}

- (void)loadView
{
    [super loadView];

    // Setup View and Table View
    self.title = @"RestKit Tweets";
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadTimeline)];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BG.png"]];
    imageView.frame = CGRectOffset(imageView.frame, 0, -64);

    [self.view insertSubview:imageView atIndex:0];

    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];

    [self loadTimeline];
}


#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize size = [[[_statuses objectAtIndex:indexPath.row] text] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(300, 9000)];
    return size.height + 30;
}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return [_statuses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = @"Tweet Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"listbg.png"]];
    }
    RKTweet* status = [_statuses objectAtIndex:indexPath.row];
    cell.textLabel.text = [status text];
    cell.detailTextLabel.text = status.user.screenName;
    return cell;
}

@end
