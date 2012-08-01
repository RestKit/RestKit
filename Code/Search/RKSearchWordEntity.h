//
//  RKSearchWordEntity.h
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString * const RKSearchWordEntityName;
extern NSString * const RKSearchWordAttributeName;
extern NSString * const RKSearchWordsRelationshipName;

/**
 Defines a Core Data entity for representing searchable text
 content in a managed object model.
 */
@interface RKSearchWordEntity : NSEntityDescription

@end
