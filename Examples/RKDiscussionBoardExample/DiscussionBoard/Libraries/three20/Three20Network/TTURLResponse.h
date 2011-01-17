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

@class TTURLRequest;

/**
 * A response protocol for TTURLRequest. This protocol is used upon the successful retrieval of
 * data from a TTURLRequest. The processResponse method is used to process the data, whether it
 * be an image or an XML string.
 *
 * @see TTURLDataResponse
 * @see TTURLImageResponse
 */
@protocol TTURLResponse <NSObject>
@required

/**
 * Processes the data from a successful request and determines if it is valid.
 *
 * If the data is not valid, return an error. The data will not be cached if there is an error.
 *
 * @param  request    The request this response is bound to.
 * @param  response   The response object, useful for getting the status code.
 * @param  data       The data received from the TTURLRequest.
 * @return NSError if there was an error parsing the data. nil otherwise.
 *
 * @required
 */
- (NSError*)request:(TTURLRequest*)request processResponse:(NSHTTPURLResponse*)response
            data:(id)data;

@end
