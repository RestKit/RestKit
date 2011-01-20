//
//  DBPostTableViewController.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBAuthenticatedTableViewController.h"
#import "DBPost.h"
#import "DBTopic.h"

@interface DBPostTableViewController : DBAuthenticatedTableViewController <RKObjectLoaderDelegate, TTTextEditorDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
	DBPost* _post;
	DBTopic* _topic;

	TTTextEditor* _bodyTextEditor;
	TTImageView* _currentAttachmentImageView;

	UIImage* _newAttachment;
}

@end
