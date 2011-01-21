//
//  DBEditTopicViewController.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import "DBAuthenticatedTableViewController.h"
#import "DBTopic.h"

@interface DBTopicViewController : DBAuthenticatedTableViewController <RKObjectLoaderDelegate> {
	UITextField* _topicNameField;
	DBTopic* _topic;
}

/**
 * The Topic that is being viewed
 */
@property (nonatomic, readonly) DBTopic* topic;

@end
