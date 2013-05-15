//
//  RKTestConstants.m
//  RestKit
//
//  Created by Blake Watters on 5/4/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

/*
 This file defines constants used by the Testing module. It is necessary due to strange
 linking errors when building for the Device. When these constants were defined within
 RKTestFactory.m, they would resolve on the Simulator but produce linker when building
 for Device. [sbw - 05/04/2012]
 */
NSString * const RKTestFactoryDefaultNamesClient = @"client";
NSString * const RKTestFactoryDefaultNamesObjectManager = @"objectManager";
NSString * const RKTestFactoryDefaultNamesManagedObjectStore = @"managedObjectStore";
NSString * const RKTestFactoryDefaultStoreFilename = @"RKTests.sqlite";
