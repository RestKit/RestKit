//
//  RKMappableObject.h
//  RestKit
//
//  Created by Jeremy Ellison on 8/17/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKObjectMappable.h"
#import "RKMappableAssociation.h"

@interface RKMappableObject : NSObject <RKObjectMappable> {
	NSDate* _dateTest;
	NSNumber* _numberTest;
	NSString* _stringTest;
    NSURL* _urlTest;
	RKMappableAssociation* _hasOne;
	NSSet* _hasMany;
}

@property (nonatomic, retain) NSDate* dateTest;
@property (nonatomic, retain) NSNumber* numberTest;
@property (nonatomic, retain) NSString* stringTest;
@property (nonatomic, retain) NSURL* urlTest;
@property (nonatomic, retain) RKMappableAssociation* hasOne;
@property (nonatomic, retain) NSSet* hasMany;

@end