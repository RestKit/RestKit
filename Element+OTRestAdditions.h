//
//  Element+OTRestAdditions.h
//  gateguru
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Element.h"

@interface Element (OTRestAdditions)

- (NSString*)contentsTextOfChildElement:(NSString*)selector;
- (NSNumber*)contentsNumber;
- (NSNumber*)contentsNumberOfChildElement:(NSString*)selector;

@end
