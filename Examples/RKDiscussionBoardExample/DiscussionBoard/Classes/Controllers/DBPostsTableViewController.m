//
//  DBPostsTableViewController.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DBPostsTableViewController.h"
#import "DBPost.h"
#import <RestKit/Three20/Three20.h>
#import "DBUser.h"

@implementation DBPostsTableViewController

- (id)initWithTopicID:(NSString*)topicID {
	if (self = [super initWithStyle:UITableViewStylePlain]) {
		_topicID = [topicID retain];
		
		self.title = @"Posts";
		_resourcePath = [[NSString stringWithFormat:@"/topics/%@/posts", _topicID] retain];
		_resourceClass = [DBPost class];
	}
	return self;
}

- (void)dealloc {
	[_topicID release];
	[super dealloc];
}

- (void)loadView {
	[super loadView];
	self.variableHeightRows = YES;
	
	UIBarButtonItem* newItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonWasPressed:)] autorelease];
	self.navigationItem.rightBarButtonItem = newItem;
}

- (void)addButtonWasPressed:(id)sender {
	NSString* url = [NSString stringWithFormat:@"db://topics/%@/posts/new", _topicID];
	TTOpenURL(url);
}

- (void)createModel {
	if (nil == [DBTopic objectWithPrimaryKeyValue:_topicID]) {
		// this topic was deleted or something.
		[self.navigationController popToRootViewControllerAnimated:YES];
		return;
	}
	[super createModel];
}

- (void)didLoadModel:(BOOL)firstTime {
	[super didLoadModel:firstTime];
	if ([self.model isKindOfClass:[RKRequestTTModel class]]) {
		RKRequestTTModel* model = (RKRequestTTModel*)self.model;
		NSMutableArray* postItems = [NSMutableArray arrayWithCapacity:[model.objects count]];
		NSMutableArray* topicItems = [NSMutableArray arrayWithCapacity:2];
		
		[topicItems addObject:[TTTableTextItem itemWithText:self.topic.name]];
		// only add edit item if there is no current user (lazy login) or
		// the current user id == topic user id.
		NSNumber* topicUserId = self.topic.userID;
		// if topicUserId is nil, the topic has no user for some reason (perhaps they got deleted).
		if ([DBUser currentUser] == nil || 
			(topicUserId && [[DBUser currentUser].userID isEqualToNumber:topicUserId])) {
			NSString* editURL = [NSString stringWithFormat:@"db://topics/%@/edit", _topicID];
			[topicItems addObject:[TTTableTextItem itemWithText:@"Edit" URL:editURL]];
		}
		
		for(DBPost* post in model.objects) {
			NSString* url = [NSString stringWithFormat:@"db://posts/%@", post.postID];
			NSString* imageURL = post.attachmentPath;
			TTTableImageItem* item = [TTTableImageItem itemWithText:post.body
														   imageURL:imageURL
																URL:url];
			[postItems addObject:item];
		}
		
		TTSectionedDataSource* dataSource = [TTSectionedDataSource dataSourceWithArrays:@"Topic",
																	  topicItems,
																	  @"Posts",
																	  postItems, nil];
		dataSource.model = model;
		self.dataSource = dataSource;
	}
}

- (DBTopic*)topic {
	return [DBTopic objectWithPrimaryKeyValue:_topicID];
}

@end
