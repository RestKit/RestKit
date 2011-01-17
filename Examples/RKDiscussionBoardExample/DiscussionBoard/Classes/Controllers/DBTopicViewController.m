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

- (id)initWithTopicID:(NSString*)topicID {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_topic = [[DBTopic objectWithPrimaryKeyValue:topicID] retain];
	}
	return self;
}

- (void)dealloc {
	[_topic release];
	[super dealloc];
}

- (BOOL)isNewRecord {
	return [[_topic topicID] intValue] == 0;
}

- (void)viewDidUnload {
	TT_RELEASE_SAFELY(_topicNameField);
}

- (void)loadView {
	self.tableViewStyle = UITableViewStyleGrouped;

	if (nil == _topic) {
		_topic = [[DBTopic object] retain];
		_topic.name = @"";
	}

	_requiresLoggedInUser = YES;
	if (![self isNewRecord]) {
		_requiredUserID = _topic.userID;
	}

	[super loadView];

	_topicNameField = [[UITextField alloc] initWithFrame:CGRectZero];
}

- (void)createModel {
	NSMutableArray* items = [NSMutableArray array];

	_topicNameField.text = _topic.name;
	[items addObject:[TTTableControlItem itemWithCaption:@"Name" control:_topicNameField]];

	if ([self isNewRecord]) {
		self.title = @"New Topic";
		[items addObject:[TTTableButton itemWithText:@"Create" delegate:self selector:@selector(createButtonWasPressed:)]];
	} else {
		self.title = @"Edit Topic";
		[items addObject:[TTTableButton itemWithText:@"Update" delegate:self selector:@selector(updateButtonWasPressed:)]];
		[items addObject:[TTTableButton itemWithText:@"Delete" delegate:self selector:@selector(destroyButtonWasPressed:)]];
	}
	self.dataSource = [TTListDataSource dataSourceWithItems:items];
}

- (void)createButtonWasPressed:(id)sender {
	_topic.name = _topicNameField.text;
	[[RKObjectManager sharedManager] postObject:_topic delegate:self];
}

- (void)updateButtonWasPressed:(id)sender {
	_topic.name = _topicNameField.text;
	[[RKObjectManager sharedManager] putObject:_topic delegate:self];
}

- (void)destroyButtonWasPressed:(id)sender {
	[[RKObjectManager sharedManager] deleteObject:_topic delegate:self];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	NSLog(@"Loaded Objects: %@", objects);
	NSLog(@"Status Code: %d", objectLoader.response.statusCode);
	// Post notification telling view controllers to reload.
	[[NSNotificationCenter defaultCenter] postNotificationName:kObjectCreatedUpdatedOrDestroyedNotificationName object:objects];
	// dismiss.
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	[[[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
}

@end
