//
//  RKSearchPredicate.m
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <RestKit/Search/RKSearchPredicate.h>
#import <RestKit/Support/RKStringTokenizer.h>

@interface RKSearchPredicate()

- (instancetype)initWithType:(NSCompoundPredicateType)type subpredicates:(NSArray *)subpredicates NS_DESIGNATED_INITIALIZER;

@end

@implementation RKSearchPredicate

+ (NSPredicate *)searchPredicateWithText:(NSString *)searchText type:(NSCompoundPredicateType)type
{
    return [[self alloc] initWithSearchText:searchText type:type];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"-initWithcoder: is not a valid initializer for the class %@, use designated initilizer -initWithSearchText:type:", NSStringFromClass([self class])]
                                 userInfo:nil];
    return [self init];
}

- (instancetype)initWithType:(NSCompoundPredicateType)type subpredicates:(NSArray *)subpredicates
{
    return [super initWithType:type subpredicates:subpredicates];
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
