//
// Copyright 2009-2010 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Standard entity tables for use with XML parsers.
 *
 * Supported entity tables: ISO 8859-1.
 *
 * Each table is a dictionary of entity names to NSData objects containing the character.
 */
@interface TTEntityTables : NSObject {
  NSDictionary* _iso88591;
}

/**
 * Entity table for ISO 8859-1.
 */
@property (nonatomic, readonly) NSDictionary* iso88591;

@end


@interface TTEntityTables (TTSingleton)

// Access the singleton instance: [[TTEntityTables sharedInstance] <methods>]
+ (TTEntityTables*)sharedInstance;

// Release the shared instance.
+ (void)releaseSharedInstance;

@end
