//
//  Element+OTRestAdditions.m
//  gateguru
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import "Element+OTRestAdditions.h"


@implementation Element (OTRestAdditions)

- (NSString*)contentsTextOfChildElement:(NSString*)selector {
	return [[self selectElement:selector] contentsText];
}

- (NSNumber*)contentsNumber {
	return [NSNumber numberWithInt:[[self contentsText] intValue]];
}

- (NSNumber*)contentsNumberOfChildElement:(NSString*)selector {
	return [[self selectElement:selector] contentsNumber];
}

@end
