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

// Network
#import "Three20Network/TTURLResponse.h"

/**
 * An implementation of the TTURLResponse protocal for UIImage objects.
 *
 * This response expects either a UIImage or an NSData object.
 * If it receives an NSData object, it updates the image cache.
 * If the image wasn't in the cache, it stores the downloaded image in the cache.
 */
@interface TTURLImageResponse : NSObject <TTURLResponse> {
  UIImage* _image;
}

@property (nonatomic, readonly) UIImage* image;

@end
