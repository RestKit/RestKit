//
//  RKOperationStateMachine.h
//  RestKit
//
//  Created by Blake Watters on 4/11/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
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

#import <Foundation/Foundation.h>

/**
 The `RKOperationStateMachine` class provides an implementation of a state machine that is suitable for implementing a concurrent `NSOperation` subclass via composition. The concurrency mechanism is a dispatch queue. The state machine takes care of correctly implementing all aspects of a concurrent `NSOperation` including:
 1. Asynchronous execution
 1. Locking
 1. Appropriate state transitions
 1. Cancellation
 1. State Instrospection

 The state machine begins its life in the ready state. Upon start, the state transitions to executing and a user-supplied execution block is invoked on the operation's dispatch queue. The operation remains in the executing state until it is finished. Just before the operation is finished, a finalization block is invoked. In the event that the operation is cancelled, then an optional cancellation block is invoked. Note that because cancellation semantics can vary widely, a cancelled operation is merely flagged as being cancelled. It is the responsibility of the operation to ensure that a cancelled operation is finished as soon as possible.

 The underlying implementation of the state machine is backed by [TransitionKit](http://github.com/blakewatters/TransitionKit)
 */
@interface RKOperationStateMachine : NSObject

- (instancetype)init __attribute__((unavailable("Invoke initWithOperation: instead.")));

///-----------------------------------
/// @name Initializing a State Machine
///-----------------------------------

/**
 Initializes a new state machine object with a given operation and dispatch queue.

 @param operation The operation that the receiver is modeling the concurrent lifecycle of.
 @param dispatchQueue The dispatch queue on which the operation executes concurrently.
 @return The receiver, initialized with the given operation and queue.
 */
- (instancetype)initWithOperation:(NSOperation *)operation dispatchQueue:(dispatch_queue_t)dispatchQueue NS_DESIGNATED_INITIALIZER;

///-----------------------
/// @name Inspecting State
///-----------------------

/**
 Returns a Boolean value that indicates if the receiver is ready to be started.

 @return `YES` if the receiver is ready to be started, else `NO`.
 */
@property (nonatomic, getter=isReady, readonly) BOOL ready;

/**
 Returns a Boolean value that indicates if the receiver is executing.

 @return `YES` if the receiver is executing, else `NO`.
 */
@property (nonatomic, getter=isExecuting, readonly) BOOL executing;

/**
 Returns a Boolean value that indicates if the receiver has been cancelled.

 @return `YES` if the receiver has been cancelled, else `NO`.
 */
@property (nonatomic, getter=isCancelled, readonly) BOOL cancelled;

/**
 Returns a Boolean value that indicates if the receiver has finished executing.

 @return `YES` if the receiver is finished, else `NO`.
 */
@property (nonatomic, getter=isFinished, readonly) BOOL finished;

///--------------------
/// @name Firing Events
///--------------------

/**
 Starts the operation by transitioning into the executing state and asychronously invoking the execution block on the operation dispatch queue.
 */
- (void)start;

/**
 Finishes the operation by transitioning from the executing state to the finished state. The state transition is executed asynchronously on the operation dispatch queue. Invokes the finalization block just before the state changes from executing to finished.
 */
- (void)finish;

/**
 Marks the operation is being cancelled. Cancellation results in state transition because cancellation semantics can vary widely. Once the cancellation flag has been set (`isCancelled` return `YES`), the cancellation block is invoked asynchronously on the operation dispatch queue. The operation must be finished as soon as possible.
 */
- (void)cancel;

///---------------------------------
/// @name Configuring Event Handlers
///---------------------------------

/**
 Sets a block to be executed on the operation dispatch queue once the operation transitions to the executing state.

 @param block The block to be executed.
 */
- (void)setExecutionBlock:(void (^)(void))block;

/**
 Sets a block to be executed when the operation is cancelled. The block will be invoked on the operation dispatch queue. Cancellation does not trigger any state transition -- the operation must still be explicitly finished as soon as possible. If appropriate, the operation may be finished within the body of the cancellation block.

 @param block The block to be executed.
 */
- (void)setCancellationBlock:(void (^)(void))block;

/**
 Sets a block to be executed when the operation is about to transition from executing to finished. This block is invoked regardless of the cancellation state. This block should be used to perform any last minute cleanup or preparation before the operation finishes.

 @param block The block to be executed.
 */
- (void)setFinalizationBlock:(void (^)(void))block;

///------------------------------
/// @name Accessing Configuration
///------------------------------

/**
 The operation that the receiver is modeling the lifecycle of.
 */
@property (nonatomic, weak, readonly) NSOperation *operation;

/**
 The dispatch queue within which the state machine executes.
 */
@property (nonatomic, assign, readonly) dispatch_queue_t dispatchQueue;

///------------------------------------------
/// @name Performing Blocks that Mutate State
///------------------------------------------

/**
 Executes a block after acquiring an exclusive lock on the receiver. This enables the block to safely mutate the state of the operation. The execution context of the block is not changed -- it is always executed within the caller's thread context. If you wish to guarantee execution on the dispatch queue backing the state machine then you must dispatch onto the queue before submitting your block for execution.
 
 @param block The block to execute after acquiring an exclusive lock on the receiver.
 */
- (void)performBlockWithLock:(void (^)(void))block;

@end

/**
 Raised when an unexpected error has occurred.
 */
extern NSString *const RKOperationFailureException;
