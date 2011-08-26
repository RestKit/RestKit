//
//  RKParent.h
//  RestKit
//
//  Created by Jeff Arena on 8/25/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RKHuman.h"

@class RKChild;

@interface RKParent : RKHuman {
}

@property (nonatomic, retain) NSSet* children;

@end
