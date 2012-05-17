//
//  NSDictionary+RKRequestSerialization.h
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import "RKRequestSerializable.h"

/*
 Extends NSDictionary to enable usage as the params of an RKRequest.

 This category provides for the serialization of the receiving NSDictionary into a URL
 encoded string representation (MIME Type application/x-www-form-urlencoded). This
 enables NSDictionary objects to act as the params for an RKRequest.

 @see RKRequestSerializable
 @see [RKRequest params]
 @class NSDictionary (RKRequestSerialization)
 */
@interface NSDictionary (RKRequestSerialization) <RKRequestSerializable>

@end
