//
//  RKManagedObjectStoreTest.m
//  RestKit
//
//  Created by Blake Watters on 7/2/11.
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

#import "RKTestEnvironment.h"
#import "RKHuman.h"
#import "RKDirectory.h"

@interface RKManagedObjectStoreTest : RKTestCase

@end

@implementation RKManagedObjectStoreTest

- (void)testInstantiationOfNewManagedObjectContextAssociatesWithObjectStore
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *context = [store newManagedObjectContext];
    assertThat([context managedObjectStore], is(equalTo(store)));
}

- (void)testCreationOfStoreInSpecificDirectoryRaisesIfDoesNotExist
{
    NSString *path = [[RKDirectory applicationDataDirectory] stringByAppendingPathComponent:@"/NonexistantSubdirectory"];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    assertThatBool(exists, is(equalToBool(NO)));
    STAssertThrows([RKManagedObjectStore objectStoreWithStoreFilename:@"Whatever.sqlite" inDirectory:path usingSeedDatabaseName:nil managedObjectModel:nil delegate:nil], nil);
}

- (void)testCreationOfStoryInApplicationDirectoryCreatesIfNonExistant
{
    // On OS X, the application directory is not created for you
    NSString *path = [RKDirectory applicationDataDirectory];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    assertThat(error, is(nilValue()));
    STAssertNoThrow([RKManagedObjectStore objectStoreWithStoreFilename:@"Whatever.sqlite" inDirectory:nil usingSeedDatabaseName:nil managedObjectModel:nil delegate:nil], nil);
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    assertThatBool(exists, is(equalToBool(YES)));
}

@end
