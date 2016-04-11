//
//  RKNSJSONSerialization.h
//  RestKit
//
//  Created by Blake Watters on 8/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import <RestKit/RKSerialization.h>

/**
 The `RKNSJSONSerialization` class conforms to the `RKSerialization` protocol and provides support for the serialization and deserialization of data in the JSON format using the Apple provided `NSJSONSerialization` class. This is the default JSON implementation for RestKit.
 
 @see http://www.json.org/
 */
@interface RKNSJSONSerialization : NSObject <RKSerialization>
@end
