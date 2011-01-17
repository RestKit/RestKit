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

// Network
#import "Three20Network/TTURLRequestCachePolicy.h"

/**
 * TTModel describes the state of an object that can be loaded from a remote source.
 *
 * By implementing this protocol, you can communicate to the user the state of network
 * activity in an object.
 */
@protocol TTModel <NSObject>

/**
 * An array of objects that conform to the TTModelDelegate protocol.
 */
- (NSMutableArray*)delegates;

/**
 * Indicates that the data has been loaded.
 *
 * Default implementation returns YES.
 */
- (BOOL)isLoaded;

/**
 * Indicates that the data is in the process of loading.
 *
 * Default implementation returns NO.
 */
- (BOOL)isLoading;

/**
 * Indicates that the data is in the process of loading additional data.
 *
 * Default implementation returns NO.
 */
- (BOOL)isLoadingMore;

/**
 * Indicates that the model is of date and should be reloaded as soon as possible.
 *
 * Default implementation returns NO.
 */
-(BOOL)isOutdated;

/**
 * Loads the model.
 *
 * Default implementation does nothing.
 */
- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more;

/**
 * Cancels a load that is in progress.
 *
 * Default implementation does nothing.
 */
- (void)cancel;

/**
 * Invalidates data stored in the cache or optionally erases it.
 *
 * Default implementation does nothing.
 */
- (void)invalidate:(BOOL)erase;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * A default implementation of TTModel does nothing other than appear to be loaded.
 */
@interface TTModel : NSObject <TTModel> {
  NSMutableArray* _delegates;
}

/**
 * Notifies delegates that the model started to load.
 */
- (void)didStartLoad;

/**
 * Notifies delegates that the model finished loading
 */
- (void)didFinishLoad;

/**
 * Notifies delegates that the model failed to load.
 */
- (void)didFailLoadWithError:(NSError*)error;

/**
 * Notifies delegates that the model canceled its load.
 */
- (void)didCancelLoad;

/**
 * Notifies delegates that the model has begun making multiple updates.
 */
- (void)beginUpdates;

/**
 * Notifies delegates that the model has completed its updates.
 */
- (void)endUpdates;

/**
 * Notifies delegates that an object was updated.
 */
- (void)didUpdateObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 * Notifies delegates that an object was inserted.
 */
- (void)didInsertObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 * Notifies delegates that an object was deleted.
 */
- (void)didDeleteObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 * Notifies delegates that the model changed in some fundamental way.
 */
- (void)didChange;

@end
