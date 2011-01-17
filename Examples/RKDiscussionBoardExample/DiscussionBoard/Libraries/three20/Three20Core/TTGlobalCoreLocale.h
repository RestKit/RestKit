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

/**
 * Gets the current system locale chosen by the user.
 *
 * This is necessary because [NSLocale currentLocale] always returns en_US.
 */
NSLocale* TTCurrentLocale();

/**
 * @return A localized string from the Three20 bundle.
 */
NSString* TTLocalizedString(NSString* key, NSString* comment);

/**
 * @return A localized description for NSURLErrorDomain errors.
 *
 * Error codes handled:
 * - NSURLErrorTimedOut
 * - NSURLErrorNotConnectedToInternet
 * - All other NSURLErrorDomain errors fall through to "Connection Error".
 */
NSString* TTDescriptionForError(NSError* error);

/**
 * @return The given number formatted as XX,XXX,XXX.XX
 *
 * TODO(jverkoey 04/19/2010): This should likely be locale-aware.
 */
NSString* TTFormatInteger(NSInteger num);
