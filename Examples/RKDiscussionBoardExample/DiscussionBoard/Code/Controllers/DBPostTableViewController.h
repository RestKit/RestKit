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

@interface DBPostTableViewController : DBAuthenticatedTableViewController <RKObjectLoaderDelegate, TTTextEditorDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
	DBPost* _post;

	TTTextEditor* _bodyTextEditor;
	TTImageView* _currentAttachmentImageView;

	UIImage* _newAttachment;
}

/**
 * The Post we are viewing
 */
@property (nonatomic, readonly) DBPost* post;

/**
 * Three20 URL dispatched intializer. Used to create a new Post against a Topic with
 * the specified primary key value.
 */
- (id)initWithTopicID:(NSString*)topicID;

@end
