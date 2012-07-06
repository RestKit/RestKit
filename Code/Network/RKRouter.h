//
//  RKRouter.h
//  RestKit
//
//  Created by Blake Watters on 6/20/12.
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
@class RKURL, RKRouteSet;

@interface RKRouter : NSObject

@property (nonatomic, retain) RKURL *baseURL;
@property (nonatomic, retain) RKRouteSet *routeSet;

- (id)initWithBaseURL:(RKURL *)baseURL;

- (RKURL *)URLForRouteNamed:(NSString *)routeName method:(out RKRequestMethod *)method;
- (RKURL *)URLForObject:(id)object method:(RKRequestMethod)method;
- (RKURL *)URLForRelationship:(NSString *)relationshipName ofObject:(id)object method:(RKRequestMethod)method;

@end
