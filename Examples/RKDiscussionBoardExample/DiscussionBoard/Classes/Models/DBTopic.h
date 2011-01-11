//
//  DBTopic.h
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>

@interface DBTopic : RKManagedObject {
	
}

@property (nonatomic, retain) NSNumber* topicID;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSNumber* userID;
@property (nonatomic, retain) NSDate* createdAt;
@property (nonatomic, retain) NSDate* updatedAt;

@end
