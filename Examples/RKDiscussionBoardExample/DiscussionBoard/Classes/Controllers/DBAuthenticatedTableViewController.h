//
//  DBAuthenticatedTableViewController.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>

@interface DBAuthenticatedTableViewController : TTTableViewController {
	BOOL _requiresLoggedInUser;
	NSNumber* _requiredUserID;
}

@end
