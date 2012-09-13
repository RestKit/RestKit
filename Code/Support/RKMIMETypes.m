//
//  RKMIMETypes.m
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

#import "RKMIMETypes.h"

NSString * const RKMIMETypeJSON = @"application/json";
NSString * const RKMIMETypeFormURLEncoded = @"application/x-www-form-urlencoded";
NSString * const RKMIMETypeXML = @"application/xml";
NSString * const RKMIMETypeTextXML = @"text/xml";

BOOL RKMIMETypeInSet(NSString *MIMEType, NSSet *MIMETypes)
{
    for (id MIMETypeStringOrRegularExpression in MIMETypes) {
        if ([MIMETypeStringOrRegularExpression isKindOfClass:[NSString class]]) {
            return [[MIMEType lowercaseString] isEqualToString:[MIMEType lowercaseString]];
        } else if ([MIMETypeStringOrRegularExpression isKindOfClass:[NSRegularExpression class]]) {
            NSRegularExpression *regex = (NSRegularExpression *) MIMETypeStringOrRegularExpression;
            NSUInteger numberOfMatches = [regex numberOfMatchesInString:[MIMEType lowercaseString] options:0 range:NSMakeRange(0, [MIMEType length])];
            return numberOfMatches > 0;
        } else {
            NSString *reason = [NSString stringWithFormat:@"Unable to evaluate match for MIME Type '%@': expected an `NSString` or `NSRegularExpression`, got a `%@`", MIMEType, NSStringFromClass([MIMEType class])];
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        }
    }
    
    return NO;
}
