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

@implementation DBPostsTableViewController

- (id)initWithTopicID:(NSString*)topicID {
	if (self = [super initWithStyle:UITableViewStylePlain]) {
		_topicID = [topicID retain];
	}
	return self;
}

- (void)dealloc {
	[_topicID release];
	[super dealloc];
}

- (void)loadView {
	[super loadView];
	self.title = @"Posts";
	self.variableHeightRows = YES;
	
	NSString* path = [NSString stringWithFormat:@"/topics/%@/posts", _topicID];
	self.model = [[[RKRequestTTModel alloc] initWithResourcePath:path] autorelease];
}

- (void)didLoadModel:(BOOL)firstTime {
	RKRequestTTModel* model = (RKRequestTTModel*)self.model;
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:[model.objects count]];
	
	for(DBPost* post in model.objects) {
		NSString* url = @"";
		[items addObject:[TTTableLongTextItem itemWithText:post.body URL:url]];
	}
	
	NSLog(@"Items: %@", items);
	self.dataSource = [TTListDataSource dataSourceWithItems:items];
}

@end
