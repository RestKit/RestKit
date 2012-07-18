//
//  RKMacros.h
//  RestKit
//
//  Created by Jawwad Ahmad on 7/18/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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
 Instead of using the normal DEPRECATED_ATTRIBUTE use DEPRECATED_ATTRIBUTE_MESSAGE(message) 
 to display a helpful recommendation message along with the deprecation message.
 */
#ifndef DEPRECATED_ATTRIBUTE_MESSAGE
#define DEPRECATED_ATTRIBUTE_MESSAGE(message) __attribute__((deprecated (message)))
#endif
