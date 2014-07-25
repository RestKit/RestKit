//
//  RKSlides.h
//  RestKit
//
//  Created by Bernhard Obereder on 25.07.14.
//  Copyright (c) 2014 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RKTopic;

@interface RKSlides : NSManagedObject

@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSSet *topic;
@end

@interface RKSlides (CoreDataGeneratedAccessors)

- (void)addTopicObject:(RKTopic *)value;
- (void)removeTopicObject:(RKTopic *)value;
- (void)addTopic:(NSSet *)values;
- (void)removeTopic:(NSSet *)values;

@end
