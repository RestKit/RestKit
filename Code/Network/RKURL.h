//
//  RKURL.h
//  RestKit
//
//  Created by Jeff Arena on 10/18/10.
//  Copyright 2010 Two Toasters
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

/**
 Extends the Cocoa NSURL base class to provide support for the concepts
 of base URL and resource path that are used extensively throughout the RestKit
 system.
 */
@interface RKURL : NSURL

@property (nonatomic, copy, readonly) NSURL *baseURL;
@property (nonatomic, copy, readonly) NSString *resourcePath;
@property (nonatomic, readonly) NSDictionary *queryParameters;

+ (id)URLWithBaseURL:(NSURL *)baseURL;
+ (id)URLWithBaseURL:(NSURL *)baseURL resourcePath:(NSString *)resourcePath;
+ (id)URLWithBaseURL:(NSURL *)baseURL resourcePath:(NSString *)resourcePath queryParameters:(NSDictionary *)queryParameters;

+ (id)URLWithBaseURLString:(NSString *)baseURLString;
+ (id)URLWithBaseURLString:(NSString *)baseURLString resourcePath:(NSString *)resourcePath;
+ (id)URLWithBaseURLString:(NSString *)baseURLString resourcePath:(NSString *)resourcePath queryParameters:(NSDictionary *)queryParameters;

// Designated initializer
- (id)initWithBaseURL:(NSURL *)theBaseURL resourcePath:(NSString *)theResourcePath queryParameters:(NSDictionary *)theQueryParameters;

- (RKURL *)URLByAppendingResourcePath:(NSString *)theResourcePath;
- (RKURL *)URLByAppendingResourcePath:(NSString *)theResourcePath queryParameters:(NSDictionary *)theQueryParameters;

- (RKURL *)URLByAppendingQueryParameters:(NSDictionary *)newQueryParameters;

/**
 Returns a new RKURL object with the baseURL of the receiver and a new resourcePath.
 
 @param newResourcePath The resource path to replace the value of resourcePath in the new instance
 @return An RKURL object with newResourcePath appended to the receiver's baseURL.
 */
- (RKURL *)URLByReplacingResourcePath:(NSString *)newResourcePath;

- (RKURL *)URLByInterpolatingResourcePathWithObject:(id)object;

@end
