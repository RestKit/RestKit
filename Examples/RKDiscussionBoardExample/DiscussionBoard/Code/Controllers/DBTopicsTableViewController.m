//
//  DBTopicsTableViewController.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20+Additions.h>
#import "DBTopicsTableViewController.h"
#import "DBTopic.h"
#import "DBUser.h"

@implementation DBTopicsTableViewController

- (id)initWithNavigatorURL:(NSURL *)URL query:(NSDictionary *)query {
	if (self = [super initWithNavigatorURL:URL query:query]) {
		self.title = @"Topics";
		_tableTitleHeaderLabel.text = @"Recent Topics";
		
		_resourcePath = [@"/topics" retain];
		_resourceClass = [DBTopic class];
	}
	return self;
}

- (void)createModel {
	[super createModel];

	UIBarButtonItem* item = nil;
	if ([[DBUser currentUser] isLoggedIn]) {
		item = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStyleBordered target:self action:@selector(logoutButtonWasPressed:)];
	}
	self.navigationItem.leftBarButtonItem = item;
	[item release];

	UIButton* newButton = [UIButton buttonWithType:UIButtonTypeCustom];
	UIImage* newButtonImage = [UIImage imageNamed:@"add.png"];
	[newButton setImage:newButtonImage forState:UIControlStateNormal];
	[newButton addTarget:self action:@selector(addButtonWasPressed:) forControlEvents:UIControlEventTouchUpInside];
	[newButton setFrame:CGRectMake(0, 0, newButtonImage.size.width, newButtonImage.size.height)];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonWasPressed:)];	
}

- (void)addButtonWasPressed:(id)sender {
	TTOpenURL(@"db://topics/new");
}

- (void)logoutButtonWasPressed:(id)sender {
	[[DBUser currentUser] logout];
}

- (void)didLoadModel:(BOOL)firstTime {
	[super didLoadModel:firstTime];
	
	RKRequestTTModel* model = (RKRequestTTModel*)self.model;
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:[model.objects count]];

	for (DBTopic* topic in model.objects) {
		NSString* topicPostsURL = RKMakePathWithObject(@"db://topics/(topicID)/posts", topic);
		[items addObject:[TTTableTextItem itemWithText:topic.name URL:topicPostsURL]];
	}

	// Ensure that the datasource's model is still the RKRequestTTModel;
	// Otherwise isOutdated will not work.
	TTListDataSource* dataSource = [TTListDataSource dataSourceWithItems:items];
	dataSource.model = model;
	self.dataSource = dataSource;
}

@end
