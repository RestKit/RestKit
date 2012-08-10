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
#import "NSBundle+RKAdditions.h"

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
    [bundle retain];
    [fixtureBundle release];
    fixtureBundle = bundle;
}

+ (NSString *)pathForFixture:(NSString *)fixtureName
{
    return [[self fixtureBundle] pathForResource:fixtureName ofType:nil];
}

#if TARGET_OS_IPHONE
+ (UIImage *)imageWithContentsOfFixture:(NSString *)fixtureName
{
    return [[self fixtureBundle] imageWithContentsOfResource:fixtureName withExtension:nil];
}
#endif

+ (NSString *)stringWithContentsOfFixture:(NSString *)fixtureName
{
    return [[self fixtureBundle] stringWithContentsOfResource:fixtureName withExtension:nil encoding:NSUTF8StringEncoding];
}

+ (NSData *)dataWithContentsOfFixture:(NSString *)fixtureName
{
    return [[self fixtureBundle] dataWithContentsOfResource:fixtureName withExtension:nil];
}

+ (NSString *)MIMETypeForFixture:(NSString *)fixtureName
{
    return [[self fixtureBundle] MIMETypeForResource:fixtureName withExtension:nil];
}

+ (id)parsedObjectWithContentsOfFixture:(NSString *)fixtureName
{
    return [[self fixtureBundle] parsedObjectWithContentsOfResource:fixtureName withExtension:nil];
}

@end
