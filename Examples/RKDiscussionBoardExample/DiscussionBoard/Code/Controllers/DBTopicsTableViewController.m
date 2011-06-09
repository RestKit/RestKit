//
//  DBTopicsTableViewController.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20+Additions.h>
#import "DBTopicsTableViewController.h"
#import "../Models/DBTopic.h"
#import "../Models/DBUser.h"

@implementation DBTopicsTableViewController

- (id)initWithNavigatorURL:(NSURL *)URL query:(NSDictionary *)query {
	if (self = [super initWithNavigatorURL:URL query:query]) {
		self.title = @"Topics";
		_tableTitleHeaderLabel.text = @"Recent Topics";
	}
	return self;
}

- (void)createModel {
    /**
     Map loaded objects into Three20 Table Item instances!
     */
    RKObjectTTTableViewDataSource* dataSource = [RKObjectTTTableViewDataSource dataSource];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[TTTableTextItem class]];
    [mapping mapKeyPath:@"name" toAttribute:@"text"];
    [mapping mapKeyPath:@"topicNavURL" toAttribute:@"URL"];
    [dataSource mapObjectClass:[DBTopic class] toTableItemWithMapping:mapping];
    RKObjectLoader* objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:@"/topics" delegate:nil];
    dataSource.model = [RKObjectLoaderTTModel modelWithObjectLoader:objectLoader];
    self.dataSource = dataSource;
    
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

@end
