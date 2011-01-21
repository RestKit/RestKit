//
//  DBEditTopicViewController.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBTopicViewController.h"
#import "DBTopic.h"
#import "DBUser.h"

@implementation DBTopicViewController

@synthesize topic = _topic;

- (id)initWithNavigatorURL:(NSURL*)URL query:(NSDictionary*)query {
	if (self = [super initWithNavigatorURL:URL query:query]) {
		_topic = [[DBTopic object] retain];
		_topic.name = @"";
	}
	
	return self;
}

- (id)initWithTopicID:(NSString*)topicID {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_topic = [[DBTopic objectWithPrimaryKeyValue:topicID] retain];
	}
	
	return self;
}

- (void)dealloc {
	TT_RELEASE_SAFELY(_topic);
	[super dealloc];
}

- (void)viewDidUnload {
	TT_RELEASE_SAFELY(_topicNameField);
}

- (void)loadView {
	[super loadView];
	
	self.tableViewStyle = UITableViewStyleGrouped;
	
	if (![self.topic isNewRecord]) {
		// Ensure we are logged in as the User who created the Topic
		self.requiredUser = self.topic.user;
	}
	[self presentLoginViewControllerIfNecessary];

	_topicNameField = [[UITextField alloc] initWithFrame:CGRectZero];
	_topicNameField.placeholder = @"topic name";
}

- (void)createModel {
	NSMutableArray* items = [NSMutableArray array];

	_topicNameField.text = self.topic.name;
	[items addObject:[TTTableControlItem itemWithCaption:@"Name" control:_topicNameField]];

	if ([self.topic isNewRecord]) {
		self.title = @"New Topic";
		[items addObject:[TTTableButton itemWithText:@"Create" delegate:self selector:@selector(createButtonWasPressed:)]];
	} else {
		self.title = @"Edit Topic";
		[items addObject:[TTTableButton itemWithText:@"Update" delegate:self selector:@selector(updateButtonWasPressed:)]];
		[items addObject:[TTTableButton itemWithText:@"Delete" delegate:self selector:@selector(destroyButtonWasPressed:)]];
	}
	
	self.dataSource = [TTListDataSource dataSourceWithItems:items];
}

#pragma mark Actions

- (void)createButtonWasPressed:(id)sender {
	self.topic.name = _topicNameField.text;
	[[RKObjectManager sharedManager] postObject:self.topic delegate:self];
}

- (void)updateButtonWasPressed:(id)sender {
	self.topic.name = _topicNameField.text;
	[[RKObjectManager sharedManager] putObject:self.topic delegate:self];
}

- (void)destroyButtonWasPressed:(id)sender {
	[[RKObjectManager sharedManager] deleteObject:self.topic delegate:self];
}

#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	// Post notification telling view controllers to reload.
	[[NSNotificationCenter defaultCenter] postNotificationName:DBContentObjectDidChangeNotification object:[objects lastObject]];
	
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	[[[[UIAlertView alloc] initWithTitle:@"Error" 
								 message:[error localizedDescription] 
								delegate:nil 
					   cancelButtonTitle:@"OK" 
					   otherButtonTitles:nil] autorelease] show];
}

@end
