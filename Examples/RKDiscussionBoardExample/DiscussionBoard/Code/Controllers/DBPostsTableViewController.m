//
//  DBPostsTableViewController.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <RestKit/Three20/Three20.h>
#import "DBPostsTableViewController.h"
#import "../Models/DBPost.h"
#import "../Models/DBUser.h"

@implementation DBPostsTableViewController

@synthesize topic = _topic;

- (id)initWithTopicID:(NSString*)topicID {
	if (self = [super initWithStyle:UITableViewStylePlain]) {
		_topic = [[DBTopic findFirstByAttribute:@"topicID" withValue:topicID] retain];		
		self.title = @"Posts";
	}
	return self;
}

- (void)dealloc {
	[_topic release];
	[super dealloc];
}

- (void)loadView {
	[super loadView];

	self.variableHeightRows = YES;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
                                               initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                               target:self
                                               action:@selector(addButtonWasPressed:)] autorelease];
}

- (void)addButtonWasPressed:(id)sender {
	NSString* URLString = RKMakePathWithObject(@"db://topics/(topicID)/posts/new", self.topic);
	TTOpenURL(URLString);
}

- (void)createModel {
	if (nil == self.topic) {
		// No topic was found -- must have been deleted. Pop the view controller
		[self.navigationController popToRootViewControllerAnimated:YES];
		return;
	}
    
    NSString* resourcePath = RKMakePathWithObject(@"/topics/(topicID)/posts", self.topic);
    RKObjectLoader* objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:resourcePath delegate:nil];
    self.model = [RKObjectLoaderTTModel modelWithObjectLoader:objectLoader];

	[super createModel];
}

- (void)didLoadModel:(BOOL)firstTime {
	[super didLoadModel:firstTime];

	if ([self.model isKindOfClass:[RKObjectLoaderTTModel class]]) {
		RKObjectLoaderTTModel* model = (RKObjectLoaderTTModel*)self.model;
		NSMutableArray* postItems = [NSMutableArray arrayWithCapacity:[model.objects count]];
		NSMutableArray* topicItems = [NSMutableArray arrayWithCapacity:2];

		[topicItems addObject:[TTTableTextItem itemWithText:self.topic.name]];
		
		// Add edit item if there is no current User to trigger lazy login or if the User owns the Topic
		if (NO == [[DBUser currentUser] isLoggedIn] || [[DBUser currentUser] canModifyObject:self.topic]) {
			NSString* editURL = RKMakePathWithObject(@"db://topics/(topicID)/edit", self.topic);
			[topicItems addObject:[TTTableTextItem itemWithText:@"Edit" URL:editURL]];
		}

		for (DBPost* post in model.objects) {
			NSString* URL = RKMakePathWithObject(@"db://posts/(postID)", post);
			NSString* imageURL = post.attachmentPath;
			TTTableImageItem* item = [TTTableImageItem itemWithText:post.body
														   imageURL:imageURL
																URL:URL];
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

@end
