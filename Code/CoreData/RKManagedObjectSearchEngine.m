//
//  RKManagedObjectSearchEngine.m
//  RestKit
//
//  Created by Jeff Arena on 3/31/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

#import "RKManagedObjectSearchEngine.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData


@implementation RKManagedObjectSearchEngine

static NSMutableCharacterSet *__removeSet;

@synthesize mode = _mode;

+ (id)searchEngine
{
    RKManagedObjectSearchEngine *searchEngine = [[[RKManagedObjectSearchEngine alloc] init] autorelease];
    return searchEngine;
}

- (id)init
{
    if (self = [super init]) {
        _mode = RKSearchModeOr;
    }

    return self;
}

#pragma mark -
#pragma mark Private

- (NSPredicate *)predicateForSearch:(NSArray *)searchTerms compoundSelector:(SEL)selector
{
    NSMutableArray *termPredicates = [NSMutableArray array];
    for (NSString *searchTerm in searchTerms) {
        [termPredicates addObject:
         [NSPredicate predicateWithFormat:@"(ANY searchWords.word beginswith %@)", searchTerm]];
    }
    return [NSCompoundPredicate performSelector:selector withObject:termPredicates];
}

#pragma mark -
#pragma mark Public

+ (NSArray *)tokenizedNormalizedString:(NSString *)string
{
    if (__removeSet == nil) {
        NSMutableCharacterSet *removeSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [removeSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
        [removeSet invert];
        __removeSet = removeSet;
    }

    NSString *scannerString = [[[[string lowercaseString] decomposedStringWithCanonicalMapping]
                               stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]
                                stringByReplacingOccurrencesOfString:@"-" withString:@" "];

    NSArray *tokens = [[[scannerString componentsSeparatedByCharactersInSet:__removeSet]
                        componentsJoinedByString:@""] componentsSeparatedByString:@" "];
    return tokens;
}

- (NSPredicate *)predicateForSearch:(NSString *)searchText
{
    NSString *searchQuery = [searchText copy];
    NSArray *searchTerms = [RKManagedObjectSearchEngine tokenizedNormalizedString:searchQuery];
    [searchQuery release];

    if ([searchTerms count] == 0) {
        return nil;
    }

    if (_mode == RKSearchModeOr) {
        return [self predicateForSearch:searchTerms
                       compoundSelector:@selector(orPredicateWithSubpredicates:)];
    } else if (_mode == RKSearchModeAnd) {
        return [self predicateForSearch:searchTerms
                       compoundSelector:@selector(andPredicateWithSubpredicates:)];
    } else {
        return nil;
    }
}

@end
