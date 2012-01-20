//
//  RKJSONParserJSONKit.m
//  RestKit
//
//  Created by Jeff Arena on 3/16/10.
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

#import "RKJSONParserJSONKit.h"
#import "JSONKit.h"

// TODO: JSONKit serializer instance should be reused to enable leverage
// the internal caching capabilities from the JSONKit serializer
@implementation RKJSONParserJSONKit

- (NSDictionary*)objectFromString:(NSString*)string error:(NSError**)error {
    return [string objectFromJSONStringWithParseOptions:JKParseOptionStrict error:error];
}

- (NSString*)stringFromObject:(id)object error:(NSError**)error {
	return [object JSONStringWithOptions:JKSerializeOptionNone error:error];
}

@end
