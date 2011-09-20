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
@interface RKURL : NSURL {
	NSString* _baseURLString;
	NSString* _resourcePath;
	NSDictionary* _queryParams;
}

@property (nonatomic, readonly) NSString* baseURLString;
@property (nonatomic, readonly) NSString* resourcePath;
@property (nonatomic, readonly) NSDictionary* queryParams;

- (id)initWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath;
- (id)initWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath queryParams:(NSDictionary*)queryParams;
+ (RKURL*)URLWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath;
+ (RKURL*)URLWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath queryParams:(NSDictionary*)queryParams;

@end
