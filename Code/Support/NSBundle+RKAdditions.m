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
#import "NSString+RKAdditions.h"
#import "UIImage+RKAdditions.h"
#import "RKLog.h"
#import "RKParser.h"
#import "RKParserRegistry.h"

@implementation NSBundle (RKAdditions)

+ (NSBundle *)restKitResourcesBundle
{
    static BOOL searchedForBundle = NO;

    if (! searchedForBundle) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"RestKitResources" ofType:@"bundle"];
        searchedForBundle = YES;
        NSBundle *resourcesBundle = [NSBundle bundleWithPath:path];
        if (! resourcesBundle) RKLogWarning(@"Unable to find RestKitResources.bundle in your project. Did you forget to add it?");
        return resourcesBundle;
    }

    return [NSBundle bundleWithIdentifier:@"org.restkit.RestKitResources"];
}

- (NSString *)MIMETypeForResource:(NSString *)name withExtension:(NSString *)extension
{
    NSString *resourcePath = [self pathForResource:name ofType:extension];
    if (resourcePath) {
        return [resourcePath MIMETypeForPathExtension];
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
        RKLogWarning(@"%@ Failed to locate Resource with name '%@' and extension '%@': File Not Found.", self, resourcePath, extension);
        return nil;
    }

    NSString *fixtureData = [NSString stringWithContentsOfFile:resourcePath encoding:encoding error:&error];
    if (fixtureData == nil && error) {
        RKLogWarning(@"Failed to read ");
    }

    return fixtureData;
}

#if TARGET_OS_IPHONE
- (UIImage *)imageWithContentsOfResource:(NSString *)name withExtension:(NSString *)extension
{
    NSString *resourcePath = [self pathForResource:name ofType:extension];
    if (! resourcePath) {
        RKLogWarning(@"%@ Failed to locate Resource with name '%@' and extension '%@': File Not Found.", self, resourcePath, extension);
        return nil;
    }

    return [UIImage imageWithContentsOfResolutionIndependentFile:resourcePath];
}
#endif

- (id)parsedObjectWithContentsOfResource:(NSString *)name withExtension:(NSString *)extension
{
    NSError *error = nil;
    NSString *resourceContents = [self stringWithContentsOfResource:name withExtension:extension encoding:NSUTF8StringEncoding];
    NSString *MIMEType = [self MIMETypeForResource:name withExtension:extension];
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:MIMEType];
    if (! parser) {
        RKLogError(@"%@ Unable to parse Resource with name '%@' and extension '%@': failed to find parser registered to handle MIME Type '%@'", self, name, extension, MIMEType);
        return nil;
    }

    id object = [parser objectFromString:resourceContents error:&error];
    if (object == nil) {
        RKLogCritical(@"%@ Failed to parse resource with name '%@' and extension '%@'. Error: %@", self, name, extension, [error localizedDescription]);
        return nil;
    }

    return object;
}

@end
