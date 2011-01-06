//
//  RKTwitterViewController.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright Two Toasters 2010. All rights reserved.
//

#import "RKTwitterViewController.h"
#import "RKTStatus.h"

@interface RKTwitterViewController (Private)
- (void)loadData;
@end

@implementation RKTwitterViewController

- (void)loadView {
    [super loadView];
	
	// Setup View and Table View
	
	self.title = @"Two Toasters Tweets";
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
	[self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
	
	UIImageView* imageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BG.png"]] autorelease];
	imageView.frame = CGRectOffset(imageView.frame, 0, -64);
	
	[self.view insertSubview:imageView atIndex:0];
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480-64) style:UITableViewStylePlain];
	_tableView.dataSource = self;
	_tableView.delegate = self;
	[self.view addSubview:_tableView];
	
	_tableView.backgroundColor = [UIColor clearColor];
	_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	// Load the object model via RestKit	
	RKObjectManager* objectManager = [RKObjectManager sharedManager];
	[objectManager loadObjectsAtResourcePath:@"/status/user_timeline/twotoasters.json" objectClass:[RKTStatus class] delegate:self];
}


- (void)dealloc {
	[_tableView release];
	[_statuses release];
    [super dealloc];
}

#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	NSLog(@"Loaded statuses: %@", objects);
	[_statuses release];
	_statuses = [objects retain];
	[_tableView reloadData];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	[alert show];
	NSLog(@"Hit error: %@", error);
}

#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGSize size = [[[_statuses objectAtIndex:indexPath.row] text] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(300, 9000)];
	return size.height + 10;
}

#pragma mark UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	return [_statuses count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString* reuseIdentifier = @"Tweet Cell";
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (nil == cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.textLabel.numberOfLines = 0;
		cell.textLabel.backgroundColor = [UIColor clearColor];
		cell.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"listbg.png"]];
	}
	cell.textLabel.text = [[_statuses objectAtIndex:indexPath.row] text];
	return cell;
}

@end
