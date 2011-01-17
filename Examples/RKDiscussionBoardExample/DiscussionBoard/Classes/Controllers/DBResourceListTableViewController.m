//
//  DBResourceListTableViewController.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBResourceListTableViewController.h"
#import "DBManagedObjectCache.h"

@implementation UINavigationBar (CustomImage)
- (void)drawRect:(CGRect)rect {
	UIImage *image = [UIImage imageNamed:@"navigationBarBackground.png"];
	[image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
}
@end

@implementation DBResourceListTableViewController

- (void)loadView {
	[super loadView];
	UIImageView* backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
	[self.navigationController.view addSubview:backgroundImage];
	[self.navigationController.view sendSubviewToBack:backgroundImage];
	[self.view setBackgroundColor:[UIColor clearColor]];
	[self.tableView setBackgroundColor:[UIColor clearColor]];

	UIView* tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 31)] autorelease];
	UIImageView* headerBackgroundImage = [[UIImageView alloc] initWithFrame:tableHeaderView.frame];
	[headerBackgroundImage setImage:[UIImage imageNamed:@"tableHeaderBackground.png"]];
	[tableHeaderView addSubview:headerBackgroundImage];
	_loadedAtLabel = [[UILabel alloc] initWithFrame:CGRectMake(210, 0, 100, 22)];
	_loadedAtLabel.textAlignment = UITextAlignmentCenter;
	_loadedAtLabel.font = [UIFont systemFontOfSize:10.0];
	_loadedAtLabel.backgroundColor = [UIColor clearColor];
	_loadedAtLabel.textColor = [UIColor colorWithRed:0.53 green:0.56 blue:0.60 alpha:1];
	[tableHeaderView addSubview:_loadedAtLabel];
	UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[reloadButton setImage:[UIImage imageNamed:@"reload.png"] forState:UIControlStateNormal];
	[reloadButton setFrame:CGRectMake(131, 0, 82, 23)];
	[reloadButton addTarget:self action:@selector(reloadButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
	[tableHeaderView addSubview:reloadButton];
	[self.view addSubview:tableHeaderView];
	UIView* tableSpacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 31)];
	self.tableView.tableHeaderView = tableSpacer;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userStateChanged:) name:kUserLoggedInNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userStateChanged:) name:kUserLoggedOutNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadNotification:) name:kObjectCreatedUpdatedOrDestroyedNotificationName object:nil];
}

- (void)reloadButtonWasPressed:(id)sender {
	[self invalidateModel];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[_loadedAtLabel release];
	_loadedAtLabel = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadNotification:(NSNotification*)note {
	[self invalidateModel];
}

- (void)userStateChanged:(NSNotification*)note {
	[self invalidateModel];
}

- (void)createModel {
	self.model = [[[RKRequestTTModel alloc] initWithResourcePath:_resourcePath] autorelease];
}

- (void)didLoadModel:(BOOL)firstTime {
	[super didLoadModel:firstTime];
	if ([self.model isKindOfClass:[RKRequestTTModel class]]) {
		RKRequestTTModel* model = (RKRequestTTModel*)self.model;

		NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
		[formatter setDateFormat:@"hh:mm:ss MM/dd/yy"];
		_loadedAtLabel.text = [formatter stringFromDate:model.loadedTime];
	}
}

@end
