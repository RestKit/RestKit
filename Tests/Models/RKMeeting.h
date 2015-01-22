//
//  RKMeeting.h
//  RestKit
//
//  Created by Bernhard Obereder on 25.07.14.
//  Copyright (c) 2014 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RKEvent.h"

@class RKTopic;

@interface RKMeeting : RKEvent

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *topics;
@end

@interface RKMeeting (CoreDataGeneratedAccessors)

- (void)insertObject:(RKTopic *)value inTopicsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTopicsAtIndex:(NSUInteger)idx;
- (void)insertTopics:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTopicsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTopicsAtIndex:(NSUInteger)idx withObject:(RKTopic *)value;
- (void)replaceTopicsAtIndexes:(NSIndexSet *)indexes withTopics:(NSArray *)values;
- (void)addTopicsObject:(RKTopic *)value;
- (void)removeTopicsObject:(RKTopic *)value;
- (void)addTopics:(NSOrderedSet *)values;
- (void)removeTopics:(NSOrderedSet *)values;
@end
