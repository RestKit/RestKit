//
//  RKMIMETypes.h
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
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

#ifdef __cplusplus
extern "C" {
#endif

/**
 MIME Type Constants
 */

/// MIME Type application/json
extern NSString * const RKMIMETypeJSON;

/// MIME Type application/x-www-form-urlencoded
extern NSString * const RKMIMETypeFormURLEncoded;

/// MIME Type application/xml
extern NSString * const RKMIMETypeXML;

/// MIME Type text/xml
extern NSString * const RKMIMETypeTextXML;

/**
 Returns `YES` if the given MIME Type matches any MIME Type identifiers in the given set.
 
 @param MIMEType The MIME Type to evaluate the match for.
 @param MIMETypes An `NSSet` object who entries are `NSString` or `NSRegularExpression` objects specifying MIME Types.
 @return `YES` if the given MIME Type matches any identifier in the set, else `NO`.
 */
BOOL RKMIMETypeInSet(NSString *MIMEType, NSSet *MIMETypes);
    
#ifdef __cplusplus
}
#endif
