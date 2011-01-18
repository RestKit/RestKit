//
//  DBResourceListTableViewController.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import <RestKit/Three20/Three20.h>

@interface DBResourceListTableViewController : TTTableViewController {
	UILabel* _loadedAtLabel;
	UILabel* _tableTitleHeaderLabel;

	NSString* _resourcePath;
	Class _resourceClass;
}

@end
