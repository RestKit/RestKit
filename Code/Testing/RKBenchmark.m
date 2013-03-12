//
//  RKBenchmark.h
//  RestKit
//
//  Derived from Benchmark class: https://gist.github.com/1479490
//  Created by Sijawusz Pur Rahnama on 03/02/09.
//  Copyleft 2009. Some rights reserved.
//

#import "RKBenchmark.h"

@interface RKBenchmark ()
@property (nonatomic, assign, readwrite) CFAbsoluteTime startTime;
@property (nonatomic, assign, readwrite) CFAbsoluteTime endTime;
@property (nonatomic, assign, readwrite) CFTimeInterval elapsedTime;
@property (nonatomic, assign, getter = isStopped) BOOL stopped;
@end

@implementation RKBenchmark

static NSMutableDictionary *__sharedBenchmarks = nil;

+ (NSMutableDictionary *)sharedBenchmarks
{
    if (!__sharedBenchmarks) {
        __sharedBenchmarks = [[NSMutableDictionary alloc] init];
    }
    return __sharedBenchmarks;
}

+ (id)instanceWithName:(NSString *)name
{
    @synchronized (self) {
        // get the benchmark or create it on-the-fly
        id benchmark = [[self sharedBenchmarks] objectForKey:name];
        if (!benchmark) {
            benchmark = [self benchmarkWithName:name];
            [[self sharedBenchmarks] setObject:benchmark forKey:name];
        }
        return benchmark;
    }
    return nil;
}

@synthesize name        = _name;
@synthesize startTime   = _startTime;
@synthesize endTime     = _endTime;
@synthesize elapsedTime = _elapsedTime;
@synthesize stopped     = _stopped;

# pragma mark -
# pragma mark Quick access class methods

+ (id)report:(NSString *)info executionBlock:(void (^)(void))block
{
    RKBenchmark *benchmark = [self instanceWithName:info];
    [benchmark run:block];
    [benchmark log];
    return benchmark;
}

+ (CFTimeInterval)measureWithExecutionBlock:(void (^)(void))block
{
    RKBenchmark *benchmark = [self new];
    [benchmark run:block];
    return benchmark.elapsedTime;
}

# pragma mark -
# pragma mark Initializers

+ (id)benchmarkWithName:(NSString *)name
{
    return [[self alloc] initWithName:name];
}

- (id)initWithName:(NSString *)name
{
    if (self = [self init]) {
        self.name = name;
    }
    return self;
}

# pragma mark -
# pragma mark Benchmark methods

- (void)run:(void (^)(void))executionBlock
{
    [self start];
    executionBlock();
    [self stop];
}

- (void)start
{
    self.startTime = CFAbsoluteTimeGetCurrent();
}

- (void)stop
{
    self.endTime = CFAbsoluteTimeGetCurrent();
    self.stopped = YES;

    // Calculate elapsed time
    CFDateRef startDate = CFDateCreate(NULL, self.startTime);
    CFDateRef endDate = CFDateCreate(NULL, self.endTime);
    self.elapsedTime = CFDateGetTimeIntervalSinceDate(endDate, startDate);
    CFRelease(startDate);
    CFRelease(endDate);
}

- (void)log
{
    CFTimeInterval timeElapsed;
    if (self.isStopped) {
        timeElapsed = self.elapsedTime;
    } else {
        CFDateRef startDate = CFDateCreate(NULL, self.startTime);
        timeElapsed = CFDateGetTimeIntervalSinceDate(startDate, (CFDateRef)[NSDate date]);
        CFRelease(startDate);
    }

    // log elapsed time
    if (_name)   NSLog(@"Benchmark '%@' took %f seconds.", _name, timeElapsed);
    else         NSLog(@"Benchmark took %f seconds.", timeElapsed);
}

@end
