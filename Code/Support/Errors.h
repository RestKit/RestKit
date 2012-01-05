//
//  Errors.h
//  RestKit
//
//  Created by Blake Watters on 3/25/10.
//  Copyright 2010 Two Toasters
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

// The error domain for RestKit generated errors
extern NSString* const RKRestKitErrorDomain;

extern NSString* const RKObjectMapperErrorObjectsKey;

typedef enum {
	RKObjectLoaderRemoteSystemError             =   1,
	RKRequestBaseURLOfflineError                =   2,
    RKRequestUnexpectedResponseError            =   3,
    RKObjectLoaderUnexpectedResponseError       =   4,
    RKRequestConnectionTimeoutError             =   5
} RKRestKitError;
