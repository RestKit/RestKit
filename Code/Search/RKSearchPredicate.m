//
//  RKSearchPredicate.m
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKSearchPredicate.h"
#import "RKStringTokenizer.h"

@implementation RKSearchPredicate

+ (NSPredicate *)searchPredicateWithText:(NSString *)searchText type:(NSCompoundPredicateType)type
{
    return [[self alloc] initWithSearchText:searchText type:type];
}

- (instancetype)initWithSearchText:(NSString *)searchText type:(NSCompoundPredicateType)type
{
    RKStringTokenizer *tokenizer = [RKStringTokenizer new];
    NSSet *searchWords = [tokenizer tokenize:searchText];

    NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:[searchWords count]];
    for (NSString *searchWord in searchWords) {
        [subpredicates addObject:[NSPredicate predicateWithFormat:@"(ANY searchWords.word beginswith %@)", searchWord]];
    }

    return [super initWithType:type subpredicates:subpredicates];
}

@end
