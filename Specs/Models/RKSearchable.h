//
//  RKSearchable.h
//  RestKit
//
//  Created by Blake Watters on 7/26/11.
//  Copyright (c) 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RKSearchableManagedObject.h"

@interface RKSearchable : RKSearchableManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * body;

@end
