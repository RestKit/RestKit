//
//  NSURL+RestKit.h
//  RestKit
//
//  Created by Blake Watters on 10/11/11.
//  Copyright 2011 RestKit
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

@interface NSURL (RestKit)

/**
 Returns the query portion of the URL as a dictionary
 */
- (NSDictionary *)queryDictionary;

/**
 Returns the MIME Type for the resource identified by the URL by interpretting the
 path extension using Core Services.
 
 For example, given a URL to http://restkit.org/monkey.json we would get 
 @"application/json" as the MIME Type.
 
 @return The expected MIME Type of the resource identified by the URL or nil if unknown
 */
- (NSString *)MIMETypeForPathExtension;

@end
