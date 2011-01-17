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

@protocol TTModel;

@protocol TTModelDelegate <NSObject>

@optional

- (void)modelDidStartLoad:(id<TTModel>)model;

- (void)modelDidFinishLoad:(id<TTModel>)model;

- (void)model:(id<TTModel>)model didFailLoadWithError:(NSError*)error;

- (void)modelDidCancelLoad:(id<TTModel>)model;

/**
 * Informs the delegate that the model has changed in some fundamental way.
 *
 * The change is not described specifically, so the delegate must assume that the entire
 * contents of the model may have changed, and react almost as if it was given a new model.
 */
- (void)modelDidChange:(id<TTModel>)model;

- (void)model:(id<TTModel>)model didUpdateObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

- (void)model:(id<TTModel>)model didInsertObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

- (void)model:(id<TTModel>)model didDeleteObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 * Informs the delegate that the model is about to begin a multi-stage update.
 *
 * Models should use this method to condense multiple updates into a single visible update.
 * This avoids having the view update multiple times for each change.  Instead, the user will
 * only see the end result of all of your changes when you call modelDidEndUpdates.
 */
- (void)modelDidBeginUpdates:(id<TTModel>)model;

/**
 * Informs the delegate that the model has completed a multi-stage update.
 *
 * The exact nature of the change is not specified, so the receiver should investigate the
 * new state of the model by examining its properties.
 */
- (void)modelDidEndUpdates:(id<TTModel>)model;

@end
