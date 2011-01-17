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

#import "Three20Network/TTURLRequestQueue.h"

@class TTRequestLoader;

/**
 * The internal interface for the TTRequestLoaders to interact with the TTURLRequestQueue.
 */
@interface TTURLRequestQueue (TTRequestLoader)

- (void)                       loader: (TTRequestLoader*)loader
    didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge*)challenge;

- (void)     loader: (TTRequestLoader*)loader
    didLoadResponse: (NSHTTPURLResponse*)response
               data: (id)data;

- (void)               loader:(TTRequestLoader*)loader
    didLoadUnmodifiedResponse:(NSHTTPURLResponse*)response;

- (void)loader:(TTRequestLoader*)loader didFailLoadWithError:(NSError*)error;
- (void)loaderDidCancel:(TTRequestLoader*)loader wasLoading:(BOOL)wasLoading;

@end
