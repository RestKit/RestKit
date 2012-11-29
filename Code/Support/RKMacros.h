//
//  RKMacros.h
//  RestKit
//
//  Created by Jawwad Ahmad on 7/18/12.
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

#ifndef RestKit_RKMacros_h
#define RestKit_RKMacros_h

/*
 Instead of using the normal DEPRECATED_ATTRIBUTE use DEPRECATED_ATTRIBUTE_MESSAGE(message)
 to display a helpful recommendation message along with the deprecation message.
 */
#ifndef DEPRECATED_ATTRIBUTE_MESSAGE
#define DEPRECATED_ATTRIBUTE_MESSAGE(message) __attribute__((deprecated (message)))
#endif

/*
 Add this macro before each category implementation, so we don't have to use
 -all_load or -force_load to load object files from static libraries that only contain
 categories and no classes.
 See http://developer.apple.com/library/mac/#qa/qa2006/qa1490.html for more info.

 Shamelessly borrowed from Three20
 */
#define RK_FIX_CATEGORY_BUG(name) @interface RK_FIX_CATEGORY_BUG##name @end \
@implementation RK_FIX_CATEGORY_BUG##name @end

/*
 Raises an `NSInvalidArgumentException` in the event that the given value is not an instance of the given class or an instance of any class that inherits from that class.
 */
#define RKAssertValueIsKindOfClass(value, expectedClass) \
if (! [value isKindOfClass:expectedClass]) { \
[NSException raise:NSInvalidArgumentException format:@"%@ invoked with invalid input value: expected a `%@`, but instead got a `%@`", [self class], expectedClass, [value class]]; \
}

#endif
