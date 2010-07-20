//
//  RKMappableAssociation.h
//  RestKit
//
//  Created by Jeremy Ellison on 8/17/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKResourceMappable.h"

@interface RKMappableAssociation : NSObject <RKResourceMappable> {
	NSString* _testString;
}

@property (nonatomic, retain) NSString* testString;

@end
