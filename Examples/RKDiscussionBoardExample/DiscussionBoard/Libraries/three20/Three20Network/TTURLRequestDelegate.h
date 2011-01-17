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

@class TTURLRequest;

@protocol TTURLRequestDelegate <NSObject>
@optional

/**
 * The request has begun loading.
 *
 * This method will not be called if the data is loaded immediately from the cache.
 * @see requestDidFinishLoad:
 */
- (void)requestDidStartLoad:(TTURLRequest*)request;

/**
 * The request has loaded some more data.
 *
 * Check the totalBytesLoaded and totalBytesExpected properties for details.
 */
- (void)requestDidUploadData:(TTURLRequest*)request;

/**
 * The request has loaded data and been processed into a response.
 *
 * If the request is served from the cache, this is the only delegate method that will be called.
 */
- (void)requestDidFinishLoad:(TTURLRequest*)request;

/**
 * Allows delegate to handle any authentication challenges.
 */
- (void)request:(TTURLRequest*)request
  didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;

/**
 * The request failed to load.
 */
- (void)request:(TTURLRequest*)request didFailLoadWithError:(NSError*)error;

/**
 * The request was canceled.
 */
- (void)requestDidCancelLoad:(TTURLRequest*)request;

@end
