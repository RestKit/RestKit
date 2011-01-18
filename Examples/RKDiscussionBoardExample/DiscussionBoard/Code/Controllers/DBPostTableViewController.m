//
//  DBPostTableViewController.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBPostTableViewController.h"
#import <Three20/Three20+Additions.h>
#import "DBUser.h"

@implementation DBPostTableViewController

- (id)initWithPostID:(NSString*)postID {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_post = [[DBPost objectWithPrimaryKeyValue:postID] retain];
	}

	return self;
}

- (id)initWithTopicID:(NSString*)topicID {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		// TODO: Why are we using topic ID here?
		_topicID = [[NSNumber numberWithInt:[topicID intValue]] retain];
	}

	return self;
}

- (void)dealloc {
	TT_RELEASE_SAFELY(_post);
	TT_RELEASE_SAFELY(_topicID);

	[super dealloc];
}

// TODO: Move this into the model
- (BOOL)isNewRecord {
	return [[_post postID] intValue] == 0;
}

- (void)viewDidUnload {
	TT_RELEASE_SAFELY(_bodyTextEditor);
	[[TTNavigator navigator].URLMap removeURL:@"db://updateAttachment"];
}

- (void)loadView {
	self.tableViewStyle = UITableViewStyleGrouped;
	self.autoresizesForKeyboard = YES;
	self.variableHeightRows = YES;

	[[TTNavigator navigator].URLMap from:@"db://updateAttachment" toObject:self selector:@selector(updateAttachment)];

	// TODO: Use self.post method?
	if (nil == _post) {
		_post = [[DBPost object] retain];
		_post.topicID = _topicID;
	}

	_requiresLoggedInUser = YES;

	[super loadView];

	_bodyTextEditor = [[TTTextEditor alloc] initWithFrame:CGRectMake(0, 0, 300, 120)];
	_bodyTextEditor.font = [UIFont systemFontOfSize:12];
	_bodyTextEditor.autoresizesToText = NO;
	_bodyTextEditor.delegate = self;
	_bodyTextEditor.text = _post.body;
}

- (void)createModel {
	// TODO: Move this into the model: [self.currentUser canModifyObject:_post]
	BOOL isAuthorizedUser = [[DBUser currentUser].userID isEqualToNumber:_post.userID] || [self isNewRecord];

	NSMutableArray* items = [NSMutableArray array];

	// Attachment item.
	if (isAuthorizedUser) {
		[items addObject:[TTTableControlItem itemWithCaption:@"" control:(UIControl*)_bodyTextEditor]];
		if (_newAttachment) {
			// has new attachment. show it. allow update.
			[items addObject:[TTTableImageItem itemWithText:@"Tap to Replace Image" imageURL:@"" defaultImage:_newAttachment URL:@"db://updateAttachment"]];
		} else if (![[_post attachmentPath] isWhitespaceAndNewlines]) {
			// TODO: Create model method to determine if there is an attachment
			// Has existing attachment. allow replace
			NSString* url = _post.attachmentPath;
			[items addObject:[TTTableImageItem itemWithText:@"Tap to Replace Image" imageURL:url defaultImage:nil URL:@"db://updateAttachment"]];
		} else {
			// has no attachment. allow new one.
			[items addObject:[TTTableTextItem itemWithText:@"Tap to Add Image" URL:@"db://updateAttachment"]];
		}
	} else {
		[items addObject:[TTTableLongTextItem itemWithText:_post.body]];
		NSString* url = _post.attachmentPath;
		[items addObject:[TTTableImageItem itemWithText:@"" imageURL:url URL:nil]];
	}

	if ([self isNewRecord]) {
		self.title = @"New Post";
		[items addObject:[TTTableButton itemWithText:@"Create" delegate:self selector:@selector(createButtonWasPressed:)]];
	} else {
		if (isAuthorizedUser) {
			self.title = @"Edit Post";
			[items addObject:[TTTableButton itemWithText:@"Update" delegate:self selector:@selector(updateButtonWasPressed:)]];
			[items addObject:[TTTableButton itemWithText:@"Delete" delegate:self selector:@selector(destroyButtonWasPressed:)]];
		} else {
			self.title = @"Post";
		}
	}
	NSString* byLine = @"";
	if (![self isNewRecord]) {
		NSString* username = (isAuthorizedUser ? @"me" : _post.username);
		byLine = [NSString stringWithFormat:@"posted by %@", username];
	}
	self.dataSource = [TTSectionedDataSource dataSourceWithArrays:byLine, items, nil];
}

- (void)updateAttachment {
	[_bodyTextEditor resignFirstResponder];
	UIImagePickerController* controller = [[[UIImagePickerController alloc] init] autorelease];
	controller.delegate = self;
	[self presentModalViewController:controller animated:YES];
}

#pragma mark Actions

- (void)createButtonWasPressed:(id)sender {
	_post.body = _bodyTextEditor.text;
	_post.newAttachment = _newAttachment;
	[[RKObjectManager sharedManager] postObject:_post delegate:self];
}

- (void)updateButtonWasPressed:(id)sender {
	_post.body = _bodyTextEditor.text;
	_post.newAttachment = _newAttachment;
	[[RKObjectManager sharedManager] putObject:_post delegate:self];
}

- (void)destroyButtonWasPressed:(id)sender {
	[[RKObjectManager sharedManager] deleteObject:_post delegate:self];
}

#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	_newAttachment = [info objectForKey:UIImagePickerControllerOriginalImage];
	[self dismissModalViewControllerAnimated:YES];
	[self invalidateModel];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	// TODO: RKLog helpers?
	NSLog(@"Loaded Objects: %@", objects);
	NSLog(@"Status Code: %d", objectLoader.response.statusCode);
	// Post notification telling view controllers to reload.
	// TODO
	[[NSNotificationCenter defaultCenter] postNotificationName:kObjectCreatedUpdatedOrDestroyedNotificationName object:objects];
	// dismiss.
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	[[[[UIAlertView alloc] initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease] show];
}

#pragma mark TTTextEditorDelegate methods

- (void)textEditorDidBeginEditing:(TTTextEditor*)textEditor {
	UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
																   style:UIBarButtonItemStyleDone
																  target:textEditor
																  action:@selector(resignFirstResponder)];
	self.navigationItem.rightBarButtonItem = doneButton;
	[doneButton release];
}

- (void)textEditorDidEndEditing:(TTTextEditor*)textEditor {
	self.navigationItem.rightBarButtonItem = nil;
}

@end
