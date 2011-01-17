//
// Copyright 2009-2010 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

/**
 * A protocol for the object that implements the backend logic for the
 * TTMessageController. This object is responsible for delivering the message
 * that was composed in the view controller when the user chooses the send option.
 * It receive a message when the user cancels the creation of a message or when
 * they press the plus icon in a recipient field.
 */
@protocol TTMessageControllerDelegate <NSObject>

@optional

/**
 * Received when the user touches the send button, indicating they wish to send
 * their message. Implementations should send the message represented by the
 * supplied fields. The fields array contains subclasses of TTMessageField. Its
 * last object is the body of the message, contained within a TTMessageTextField.
 */
- (void)composeController:(TTMessageController*)controller didSendFields:(NSArray*)fields;

/**
 * Received when the user has chosen to cancel creating their message. Upon
 * returning, the TTMessageController will be dismissed. Implementations
 * can use this callback to cleanup any resources.
 */
- (void)composeControllerWillCancel:(TTMessageController*)controller;

/**
 * Received in response to the user touching a contact add button. This method
 * should prepare and present a view for the user to choose a contact. Upon
 * choosing a contact, that contact should be added to the field.
 */
- (void)composeControllerShowRecipientPicker:(TTMessageController*)controller;

@end
