//
//  RKChild.h
//  RestKit
//
//  Created by Jeff Arena on 8/25/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RKHuman.h"

@class RKParent;

@interface RKChild : RKHuman {
}

@property (nonatomic, retain) NSSet* parents;

@end
