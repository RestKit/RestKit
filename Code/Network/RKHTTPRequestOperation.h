//
//  RKHTTPRequestOperation.h
//  RestKit
//
//  Created by Blake Watters on 8/7/12.
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

#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"

// TODO: AFNetworking should expose the default headers dictionary...
@interface AFHTTPClient ()
@property (readonly, nonatomic) NSDictionary *defaultHeaders;
@end

// NOTE: Accepts 2xx and 4xx status codes, application/json only.
// TODO: May want to factor this down into another more specific operation subclass to generalize the behavior
@interface RKHTTPRequestOperation : AFHTTPRequestOperation

// We allow override of status codes and content types on a per-request basis
@property (nonatomic, strong) NSIndexSet *acceptableStatusCodes; // Default nil: means defer to class level
@property (nonatomic, strong) NSSet *acceptableContentTypes;     // Default nil: means defer to class level

@end
