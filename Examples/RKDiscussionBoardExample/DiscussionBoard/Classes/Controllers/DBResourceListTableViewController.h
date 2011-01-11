//
//  DBResourceListTableViewController.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import <RestKit/Three20/Three20.h>

@interface DBResourceListTableViewController : TTTableViewController {
	UILabel* _loadedAtLabel;
	
	NSString* _resourcePath;
	Class _resourceClass;
}

@end
