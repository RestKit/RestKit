//
//  DBTopic.m
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBTopic.h"

@implementation DBTopic

@dynamic topicID;
@dynamic name;
@dynamic posts;

- (BOOL)isNewRecord {
	return [self.topicID intValue] == 0;
}

- (NSString*)topicNavURL {
    return RKMakePathWithObject(@"db://topics/(topicID)/posts", self);
}

@end
