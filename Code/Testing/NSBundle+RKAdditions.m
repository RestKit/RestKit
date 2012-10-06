//
//  NSBundle+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 2/1/12.
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

#import "NSBundle+RKAdditions.h"
#import "RKPathUtilities.h"
#import "RKLog.h"
#import "RKSerialization.h"
#import "RKMIMETypeSerialization.h"

@implementation NSBundle (RKAdditions)

- (NSString *)MIMETypeForResource:(NSString *)name withExtension:(NSString *)extension
{
    NSString *resourcePath = [self pathForResource:name ofType:extension];
    if (resourcePath) {
        return RKMIMETypeFromPathExtension(resourcePath);
    }

    return nil;
}

- (NSData *)dataWithContentsOfResource:(NSString *)name withExtension:(NSString *)extension
{
    NSString *resourcePath = [self pathForResource:name ofType:extension];
    if (! resourcePath) {
        RKLogWarning(@"%@ Failed to locate Resource with name '%@' and extension '%@': File Not Found.", self, resourcePath, extension);
        return nil;
    }

    return [NSData dataWithContentsOfFile:resourcePath];
}

- (NSString *)stringWithContentsOfResource:(NSString *)name withExtension:(NSString *)extension encoding:(NSStringEncoding)encoding
{
    NSError *error = nil;
    NSString *resourcePath = [self pathForResource:name ofType:extension];
    if (! resourcePath) {
        RKLogWarning(@"%@ Failed to locate Resource with name '%@' and extension '%@': File Not Found.", self, name, extension);
        return nil;
    }

    NSString *fixtureData = [NSString stringWithContentsOfFile:resourcePath encoding:encoding error:&error];
    if (fixtureData == nil && error) {
        RKLogWarning(@"Failed to read ");
    }

    return fixtureData;
}

- (id)parsedObjectWithContentsOfResource:(NSString *)name withExtension:(NSString *)extension
{
    NSError *error = nil;
    NSData *resourceContents = [self dataWithContentsOfResource:name withExtension:extension];
    NSString *MIMEType = [self MIMETypeForResource:name withExtension:extension];

    id object = [RKMIMETypeSerialization objectFromData:resourceContents MIMEType:MIMEType error:&error];
    if (object == nil) {
        RKLogCritical(@"%@ Failed to parse resource with name '%@' and extension '%@'. Error: %@", self, name, extension, [error localizedDescription]);
        return nil;
    }

    return object;
}

@end
