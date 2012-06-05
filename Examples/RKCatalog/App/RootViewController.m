//
//  RootViewController.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RootViewController.h"

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _exampleTableItems = [[NSArray alloc] initWithObjects:
                          @"RKAuthenticationExample",
                          @"RKParamsExample",
                          @"RKRequestQueueExample",
                          @"RKReachabilityExample",
                          @"RKBackgroundRequestExample",
                          @"RKKeyValueMappingExample",
                          @"RKRelationshipMappingExample",
                          @"RKCoreDataExample",
                          nil];
}

- (void)dealloc
{
    [_exampleTableItems release];

    [super dealloc];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_exampleTableItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"RKCatalogCellIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    NSString *exampleName = [_exampleTableItems objectAtIndex:indexPath.row];
    cell.textLabel.text = exampleName;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Clear the singleton instances to isolate the examples
    [RKClient setSharedClient:nil];
    [RKObjectManager setSharedManager:nil];

    NSString *exampleName = [_exampleTableItems objectAtIndex:indexPath.row];
    Class exampleClass = NSClassFromString(exampleName);
    UIViewController *exampleController = [[exampleClass alloc] initWithNibName:exampleName bundle:nil];
    if (exampleController) {
        [self.navigationController pushViewController:exampleController animated:YES];
        if (exampleController.title == nil) {
            exampleController.title = exampleName;
        }
        [exampleController release];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
