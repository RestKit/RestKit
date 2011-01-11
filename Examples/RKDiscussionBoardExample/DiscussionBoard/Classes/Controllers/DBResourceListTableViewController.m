//
//  DBResourceListTableViewController.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DBResourceListTableViewController.h"
#import "DBManagedObjectCache.h"

@implementation DBResourceListTableViewController

- (void)loadView {
	[super loadView];
	
	UIView* tableHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 90)] autorelease];
	_loadedAtLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 300, 20)];
	_loadedAtLabel.textAlignment = UITextAlignmentCenter;
	[tableHeaderView addSubview:_loadedAtLabel];
	UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[reloadButton setTitle:@"Reload" forState:UIControlStateNormal];
	[reloadButton addTarget:self action:@selector(reloadButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
	reloadButton.frame = CGRectMake(100, 40, 100, 40);
	[tableHeaderView addSubview:reloadButton];
	
	self.tableView.tableHeaderView = tableHeaderView;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userStateChanged:) name:kUserLoggedInNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userStateChanged:) name:kUserLoggedOutNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadNotification:) name:kObjectCreatedUpdatedOrDestroyedNotificationName object:nil];
}

- (void)reloadButtonWasPressed:(id)sender {
	[self invalidateModel];
}

- (void)viewDidUnload {
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

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)createModel {
	self.model = [[[RKRequestTTModel alloc] initWithResourcePath:_resourcePath] autorelease];
}

- (void)didLoadModel:(BOOL)firstTime {
	if ([self.model isKindOfClass:[RKRequestTTModel class]]) {
		RKRequestTTModel* model = (RKRequestTTModel*)self.model;
		
		NSDateFormatter* formatter = [[[NSDateFormatter alloc] init] autorelease];
		[formatter setDateFormat:@"hh:mm:ss MM/dd/yy"];
		_loadedAtLabel.text = [NSString stringWithFormat:@"Loaded At: %@", [formatter stringFromDate:model.loadedTime]];
	}
}

@end
