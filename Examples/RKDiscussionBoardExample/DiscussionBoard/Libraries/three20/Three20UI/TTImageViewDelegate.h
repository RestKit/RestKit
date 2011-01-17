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
#import <UIKit/UIKit.h>

@class TTImageView;

@protocol TTImageViewDelegate <NSObject>
@optional

/**
 * Called when the image begins loading asynchronously.
 */
- (void)imageViewDidStartLoad:(TTImageView*)imageView;

/**
 * Called when the image finishes loading asynchronously.
 */
- (void)imageView:(TTImageView*)imageView didLoadImage:(UIImage*)image;

/**
 * Called when the image failed to load asynchronously.
 * If error is nil then the request was cancelled.
 */
- (void)imageView:(TTImageView*)imageView didFailLoadWithError:(NSError*)error;

@end
