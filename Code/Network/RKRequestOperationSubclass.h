//
//  RKRequestOperationSubclass.h
//  RestKit
//
//  Created by Blake Watters on 9/16/12.
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
 The extensions to the `RKObjectRequestOperation` class declared in the `ForSubclassEyesOnly` category are to be used by subclasses implementations only. Code that uses `RKObjectRequestOperation` objects must never call these methods.
 */
@interface RKObjectRequestOperation (ForSubclassEyesOnly)

///----------------------------
/// @name Subclassing Overrides
///----------------------------

/**
 Performs object mapping using the `response` and `responseData` properties.

 The `RKObjectRequestOperation` superclass is responsible for the invocation of this method and the subsequent handling of the mapping result or error.

 @param error A pointer to an `NSError` object to be set in the event that the object mapping process has failed.
 @return A mapping result or `nil` if an error has occurred.
 */
- (RKMappingResult *)performMappingOnResponse:(NSError **)error;

/**
 Invoked to tell the receiver that the object request operation is finishing its work and is about to transition into the finished state. Used to perform any necessary cleanup before the operation is finished.
 */
- (void)willFinish;

@end
