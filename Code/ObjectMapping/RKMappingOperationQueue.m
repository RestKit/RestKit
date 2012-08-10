//
//  RKMappingOperationQueue.m
//  RestKit
//
//  Created by Blake Watters on 9/20/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKMappingOperationQueue.h"

@implementation RKMappingOperationQueue

- (id)init
{
    self = [super init];
    if (self) {
        _operations = [NSMutableArray new];
    }

    return self;
}

- (void)dealloc
{
    [_operations release];
    [super dealloc];
}

- (void)addOperation:(NSOperation *)op
{
    [_operations addObject:op];
}

- (void)addOperationWithBlock:(void (^)(void))block
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:block];
    [_operations addObject:blockOperation];
}

- (NSArray *)operations
{
    return [NSArray arrayWithArray:_operations];
}

- (NSUInteger)operationCount
{
    return [_operations count];
}

- (void)waitUntilAllOperationsAreFinished
{
    for (NSOperation *operation in _operations) {
        [operation start];
    }
}

@end
