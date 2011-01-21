//
//  DBPostsTableViewController.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import "DBResourceListTableViewController.h"
#import "DBTopic.h"

/**
 * Displays a table of Posts within a given Topic
 */
@interface DBPostsTableViewController : DBResourceListTableViewController {
	DBTopic* _topic;
}

/**
 * The Topic we are viewing Posts within
 */
@property (nonatomic, readonly) DBTopic* topic;

@end
