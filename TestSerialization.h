//
//  TestSerialization.h
//  OTRestFramework
//
//  Created by Jeremy Ellison on 8/17/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRestModelMappableProtocol.h"
#import "TestSerializationAssociation.h"

@interface TestSerialization : NSObject <OTRestModelMappable>
{
	NSDate* _dateTest;
	NSNumber* _numberTest;
	NSString* _stringTest;
	TestSerializationAssociation* _hasOne;
	NSSet* _hasMany;
}

@property (nonatomic, retain) NSDate* dateTest;
@property (nonatomic, retain) NSNumber* numberTest;
@property (nonatomic, retain) NSString* stringTest;
@property (nonatomic, retain) TestSerializationAssociation* hasOne;
@property (nonatomic, retain) NSSet* hasMany;

@end