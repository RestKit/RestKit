//
//  RKBenchmark.h
//  RestKit
//
//  Derived from Benchmark class: https://gist.github.com/1479490
//  Created by Sijawusz Pur Rahnama on 03/02/09.
//  Copyleft 2009. Some rights reserved.
//

#import <Foundation/Foundation.h>

/**
 RKBenchmark objects provide a simple, lightweight interface for
 quickly benchmarking the performance of units of code. Benchmark
 objects can be used procedurally, by manually starting & stopping
 the benchmark, or using a block interface to measure the execution
 time of the block.
 */
@interface RKBenchmark : NSObject

///-----------------------------------------------------------------------------
/// @name Accessing Benchmark Values
///-----------------------------------------------------------------------------

/**
 A name for the benchmark. Can be nil.
 */
@property (nonatomic, retain) NSString *name;

/**
 The start time of the benchmark as an absolute time value.
 */
@property (nonatomic, assign, readonly) CFAbsoluteTime startTime;

/**
 The end time of the benchmark as an absolute time value.
 */
@property (nonatomic, assign, readonly) CFAbsoluteTime endTime;

/**
 The elapsed time of the benchmark as determined by subtracting the
 end time from the start time. Returns zero until the benchmark has
 been stopped.
 */
@property (nonatomic, assign, readonly) CFTimeInterval elapsedTime;

///-----------------------------------------------------------------------------
/// @name Quickly Performing Benchmarks
///-----------------------------------------------------------------------------

/**
 */
+ (id)report:(NSString *)info executionBlock:(void (^)(void))block;

/**
 Performs a benchmark and returns a time interval measurement of the
 total time elapsed during the execution of the blocl.

 @param block A block to execute and measure the elapsed time during execution.
 @return A time interval equal to the total time elapsed during execution.
 */
+ (CFTimeInterval)measureWithExecutionBlock:(void (^)(void))block;

///-----------------------------------------------------------------------------
/// @name Creating Benchmark Objects
///-----------------------------------------------------------------------------

/**
 Retrieves or creates a benchmark object instance with a given name.

 @param name A name for the benchmark.
 @return A new or existing benchmark object with the given name.
 */
+ (RKBenchmark *)instanceWithName:(NSString *)name;

/**
 Creates and returns a benchmark object with a name.

 @param name A name for the benchmark.
 @return A new benchmark object with the given name.
 */
+ (id)benchmarkWithName:(NSString *)name;

/**
 Initializes a new benchmark object with a name.

 @param name The name to initialize the receiver with.
 @return The receiver, initialized with the given name.
 */
- (id)initWithName:(NSString *)name;

///-----------------------------------------------------------------------------
/// @name Performing Benchmarks
///-----------------------------------------------------------------------------

/**
 Runs a benchmark by starting the receiver, executing the block, and then stopping
 the benchmark object.

 @param executionBlock A block to execute as the body of the benchmark.
 */
- (void)run:(void (^)(void))executionBlock;

/**
 Starts the benchmark by recording the start time.
 */
- (void)start;

/**
 Stops the benchmark by recording the stop time.
 */
- (void)stop;

/**
 Logs the current benchmark status. If the receiver has been stopped, the
 elapsed time of the benchmark is logged. If the benchmark is still running,
 the total time since the benchmark was started is logged.
 */
- (void)log;

@end
