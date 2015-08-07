//
//  RKTestEnvironment.m
//  RestKit
//
//  Created by Blake Watters on 3/14/11.
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

#import <objc/runtime.h>
#import "RKTestEnvironment.h"

@implementation RKTestCase

+ (void)initialize
{
    // Configure fixture bundle. The 'org.restkit.tests' identifier is shared between
    // the logic and application test bundles
    NSBundle *fixtureBundle = [NSBundle bundleWithIdentifier:@"org.restkit.tests"];
    [RKTestFixture setFixtureBundle:fixtureBundle];

    // Ensure the required directories exist
    BOOL directoryExists;
    NSError *error = nil;
    directoryExists = RKEnsureDirectoryExistsAtPath(RKApplicationDataDirectory(), &error);
    if (! directoryExists) {
        RKLogError(@"Failed to create application data directory. Unable to run tests: %@", error);
        NSAssert(directoryExists, @"Failed to create application data directory.");
    }

    directoryExists = RKEnsureDirectoryExistsAtPath(RKCachesDirectory(), &error);
    if (! directoryExists) {
        RKLogError(@"Failed to create caches directory. Unable to run tests: %@", error);
        NSAssert(directoryExists, @"Failed to create caches directory.");
    }
    
    // Configure logging from the environment variable. See RKLog.h for details
    RKLogConfigureByName("*", RKLogLevelOff);
    RKLogConfigureFromEnvironment();
    
    // Configure the Test Factory to use a specific model file
    [RKTestFactory defineFactory:RKTestFactoryDefaultNamesManagedObjectStore withBlock:^id {
        NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:RKTestFactoryDefaultStoreFilename];
        NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
        NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
        NSError *error;
        NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
        if (persistentStore) {
            BOOL success = [managedObjectStore resetPersistentStores:&error];
            if (! success) {
                RKLogError(@"Failed to reset persistent store: %@", error);
            }
        }
        
        return managedObjectStore;
    }];
}

@end
