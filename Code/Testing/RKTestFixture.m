//
//  RKTestFixture.m
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

#import "RKTestFixture.h"
#import "RKLog.h"
#import "RKPathUtilities.h"
#import "RKMIMETypeSerialization.h"

static NSBundle *fixtureBundle = nil;

@implementation RKTestFixture

+ (NSBundle *)fixtureBundle
{
    NSAssert(fixtureBundle != nil, @"Bundle for fixture has not been set. Use setFixtureBundle: to set it.");
    return fixtureBundle;
}

+ (void)setFixtureBundle:(NSBundle *)bundle
{
    NSAssert(bundle != nil, @"Bundle for fixture cannot be nil.");
    fixtureBundle = bundle;
}

+ (NSString *)pathForFixture:(NSString *)fixtureName
{
    return [[self fixtureBundle] pathForResource:fixtureName ofType:nil];
}

+ (NSString *)stringWithContentsOfFixture:(NSString *)fixtureName
{
    NSError *error = nil;
    NSString *resourcePath = [[self fixtureBundle] pathForResource:fixtureName ofType:nil];
    if (! resourcePath) {
        RKLogWarning(@"Failed to locate Fixture named '%@' in bundle %@: File Not Found.", fixtureName, [self fixtureBundle]);
        return nil;
    }
    
    NSString *fixtureData = [NSString stringWithContentsOfFile:resourcePath encoding:NSUTF8StringEncoding error:&error];
    if (fixtureData == nil && error) {
        RKLogWarning(@"Failed to read ");
    }
    
    return fixtureData;
}

+ (NSData *)dataWithContentsOfFixture:(NSString *)fixtureName
{
    NSString *resourcePath = [[self fixtureBundle] pathForResource:fixtureName ofType:nil];
    if (! resourcePath) {
        RKLogWarning(@"Failed to locate Fixture named '%@' in bundle %@: File Not Found.", fixtureName, [self fixtureBundle]);
        return nil;
    }
    
    return [NSData dataWithContentsOfFile:resourcePath];
}

+ (NSString *)MIMETypeForFixture:(NSString *)fixtureName
{
    NSString *resourcePath = [[self fixtureBundle] pathForResource:fixtureName ofType:nil];
    if (resourcePath) {
        return RKMIMETypeFromPathExtension(resourcePath);
    }
    
    return nil;
}

+ (id)parsedObjectWithContentsOfFixture:(NSString *)fixtureName
{
    NSError *error = nil;
    NSData *resourceContents = [self dataWithContentsOfFixture:fixtureName];
    NSAssert(resourceContents, @"Failed to read fixture named '%@'", fixtureName);
    NSString *MIMEType = [self MIMETypeForFixture:fixtureName];
    NSAssert(MIMEType, @"Failed to determine MIME type of fixture named '%@'", fixtureName);
    
    id object = [RKMIMETypeSerialization objectFromData:resourceContents MIMEType:MIMEType error:&error];
    NSAssert(object, @"Failed to parse fixture name '%@' in bundle %@. Error: %@", fixtureName, [self fixtureBundle], [error localizedDescription]);
    return object;
}

@end
