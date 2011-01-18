//
//  DBPostsTableViewController.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import "DBResourceListTableViewController.h"
#import "DBTopic.h"

@interface DBPostsTableViewController : DBResourceListTableViewController {
	NSString* _topicID;
}

@property (nonatomic, readonly) DBTopic* topic;

@end
