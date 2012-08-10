//
//  NSData+RKAdditions.h
//  RestKit
//
//  Created by Jeff Arena on 4/4/11.
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

/**
 Provides extensions to NSData for various common tasks.
 */
@interface NSData (RKAdditions)

/**
 Returns a string of the MD5 sum of the receiver.

 @return A new string containing the MD5 sum of the receiver.
 */
- (NSString *)MD5;

@end
