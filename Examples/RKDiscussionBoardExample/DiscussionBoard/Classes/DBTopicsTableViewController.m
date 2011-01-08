//
//  DBTopicsTableViewController.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DBTopicsTableViewController.h"
#import <RestKit/Three20/Three20.h>
#import "DBTopic.h"

@implementation DBTopicsTableViewController

- (void)loadView {
	[super loadView];
	self.title = @"Topics";
	
	self.model = [[[RKRequestTTModel alloc] initWithResourcePath:@"/topics"] autorelease];
}

- (void)didLoadModel:(BOOL)firstTime {
	RKRequestTTModel* model = (RKRequestTTModel*)self.model;
	NSMutableArray* items = [NSMutableArray arrayWithCapacity:[model.objects count]];
	
	for(DBTopic* topic in model.objects) {
		NSString* url = [NSString stringWithFormat:@"db://topics/%@/posts", topic.topicID];
		[items addObject:[TTTableTextItem itemWithText:topic.name URL:url]];
	}
	NSLog(@"Items: %@", items);
	self.dataSource = [TTListDataSource dataSourceWithItems:items];
}

@end
