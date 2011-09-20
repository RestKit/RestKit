//
//  RKJSONParserSBJSON.m
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
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

#import "RKJSONParserSBJSON.h"
#import "SBJsonParser.h"
#import "SBJsonWriter.h"

@implementation RKJSONParserSBJSON

- (NSDictionary*)objectFromString:(NSString*)string error:(NSError **)error {
	SBJsonParser* parser = [[SBJsonParser alloc] init];
	id result = [parser objectWithString:string];
	if (nil == result) {
//        if (error) *error = [[parser errorTrace] lastObject];
	}
	[parser release];
	
	return result;
}

- (NSString*)stringFromObject:(id)object error:(NSError **)error {
    SBJsonWriter *jsonWriter = [SBJsonWriter new];    
    NSString *json = [jsonWriter stringWithObject:object];
    if (!json) {
//        if (error) *error = [[jsonWriter errorTrace] lastObject];
    }
    [jsonWriter release];
    return json;
}

@end
