//
//  RKMappingOperationQueue.h
//  RestKit
//
//  Created by Blake Watters on 9/20/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Provides a simple interface for deferring portion of an larger object mapping
 operation until the entire aggregate operation has completed. This is used by Core
 Data to connect all object relationships once the entire object graph has been mapped,
 rather than as each object is encountered.

 Designed as a lightweight workalike for NSOperationQueue, which was not usable do to
 its reliance on threading for concurrent operations. The threading was causing problems
 with managed objects due to MOC being thread specific.

 This class is not intended to be thread-safe and is used for queueing non-concurrent
 operations that will be executed within the object mapper only. It is not a general purpose
 work queue.
 */
@interface RKMappingOperationQueue : NSObject {
 @protected
    NSMutableArray *_operations;
}

/**
 Adds an NSOperation to the queue for later execution

 @param op The operation to enqueue
 */
- (void)addOperation:(NSOperation *)op;

/**
 Adds an NSBlockOperation to the queue configured to executed the block passed

 @param block A block to wrap into an operation for later execution
 */
- (void)addOperationWithBlock:(void (^)(void))block;

/**
 Returns the collection of operations in the queue

 @return A new aray containing the NSOperation objects in the order in which they were added to the queue
 */
- (NSArray *)operations;

/**
 Returns the number of operations in the queue

 @return The number of operations in the queue.
 */
- (NSUInteger)operationCount;

/**
 Starts the execution of all operations in the queue in the order in which they were added to the queue. The
 current threads execution will be blocked until all enqueued operations have returned.
 */
- (void)waitUntilAllOperationsAreFinished;

@end
