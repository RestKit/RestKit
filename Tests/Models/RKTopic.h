//
//  RKTopic.h
//  RestKit
//
//  Created by Bernhard Obereder on 25.07.14.
//  Copyright (c) 2014 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RKMeeting, RKSlides;

@interface RKTopic : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) RKMeeting *meeting;
@property (nonatomic, retain) RKSlides *slides;

@end
