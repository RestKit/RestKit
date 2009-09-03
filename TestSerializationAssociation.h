//
//  TestSerializationAssociation.h
//  OTRestFramework
//
//  Created by Jeremy Ellison on 8/17/09.
//  Copyright 2009 Objective3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRestModelMappableProtocol.h"

@interface TestSerializationAssociation : NSObject <OTRestModelMappable>
{
	NSString* _testString;
}

@property (nonatomic, retain) NSString* testString;

@end