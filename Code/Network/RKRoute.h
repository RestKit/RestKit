//
//  RKRoute.h
//  RestKit
//
//  Created by Blake Watters on 5/31/12.
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

#import "RKRequest.h"

// Class cluster. Not to be directly instantiated.
@interface RKRoute : NSObject

@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, retain, readonly) Class objectClass;
@property (nonatomic, assign, readonly) RKRequestMethod method;
@property (nonatomic, retain, readonly) NSString *resourcePathPattern;

@property (nonatomic, assign) BOOL shouldEscapeResourcePath; // when YES, the path will be escaped when interpolated

+ (id)routeWithName:(NSString *)name resourcePathPattern:(NSString *)resourcePathPattern method:(RKRequestMethod)method;
+ (id)routeWithClass:(Class)objectClass resourcePathPattern:(NSString *)resourcePathPattern method:(RKRequestMethod)method;
+ (id)routeWithRelationshipName:(NSString *)name objectClass:(Class)objectClass resourcePathPattern:(NSString *)resourcePathPattern method:(RKRequestMethod)method;

- (BOOL)isNamedRoute;
- (BOOL)isClassRoute;
- (BOOL)isRelationshipRoute;

@end
