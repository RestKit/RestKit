//
//  NSDictionary+RKRequestSerialization.m
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters
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

#import "NSDictionary+RKRequestSerialization.h"
#import "NSString+RestKit.h"
#import "RKFixCategoryBug.h"

RK_FIX_CATEGORY_BUG(NSDictionary_RKRequestSerialization)


@implementation NSDictionary (RKRequestSerialization)

- (void)URLEncodePart:(NSMutableArray*)parts path:(NSString*)path value:(id)value {
    NSString *encodedPart = [[value description] stringByAddingURLEncoding];
    [parts addObject:[NSString stringWithFormat: @"%@=%@", path, encodedPart]];
}

- (void)URLEncodeParts:(NSMutableArray*)parts path:(NSString*)inPath {
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *encodedKey = [[key description] stringByAddingURLEncoding];
        NSString *path = inPath ? [inPath stringByAppendingFormat:@"[%@]", encodedKey] : encodedKey;
        
        if ([value isKindOfClass:[NSArray class]]) {
			for (id item in value) {
                if ([item isKindOfClass:[NSDictionary class]] || [item isKindOfClass:[NSMutableDictionary class]]) {
                    [item URLEncodeParts:parts path:[path stringByAppendingString:@"[]"]];
                } else {
                    [self URLEncodePart:parts path:[path stringByAppendingString:@"[]"] value:item];
                }

            }
        } else if([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]]) {
            [value URLEncodeParts:parts path:path];
        }
        else {
            [self URLEncodePart:parts path:path value:value];
        }
    }];
}

// TODO: Move to NSDictionary+RestKit
- (NSString *)stringWithURLEncodedEntries {
    NSMutableArray* parts = [NSMutableArray array];
    [self URLEncodeParts:parts path:nil];
    return [parts componentsJoinedByString:@"&"];
}

- (NSString *)URLEncodedString {
    return [self stringWithURLEncodedEntries];
}

- (NSString *)HTTPHeaderValueForContentType {
	return @"application/x-www-form-urlencoded";
}

- (NSData*)HTTPBody {
	return [[self URLEncodedString] dataUsingEncoding:NSUTF8StringEncoding];
}

@end
