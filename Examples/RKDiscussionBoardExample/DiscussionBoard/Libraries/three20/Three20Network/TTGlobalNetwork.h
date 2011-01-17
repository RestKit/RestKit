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

#define TT_DEFAULT_CACHE_INVALIDATION_AGE (60*60*24)    // 1 day
#define TT_DEFAULT_CACHE_EXPIRATION_AGE   (60*60*24*7)  // 1 week
#define TT_CACHE_EXPIRATION_AGE_NEVER     (1.0 / 0.0)   // inf

/**
 * Increment the number of active network requests.
 *
 * The status bar activity indicator will be spinning while there are active requests.
 *
 * @threadsafe
 */
void TTNetworkRequestStarted();

/**
 * Decrement the number of active network requests.
 *
 * The status bar activity indicator will be spinning while there are active requests.
 *
 * @threadsafe
 */
void TTNetworkRequestStopped();

///////////////////////////////////////////////////////////////////////////////////////////////////
// Images

#define TTIMAGE(_URL) [[TTURLCache sharedCache] imageForURL:_URL]
