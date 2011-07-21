//
//  RKMappableAssociation.h
//  RestKit
//
//  Created by Jeremy Ellison on 8/17/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKMappableAssociation : NSObject {
	NSString* _testString;
    NSDate* _date;
}

@property (nonatomic, retain) NSString* testString;
@property (nonatomic, retain) NSDate* date;

@end
