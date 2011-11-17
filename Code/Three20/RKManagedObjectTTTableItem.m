//
//  RKManagedObjectTTTableItem.m
//  RestKit
//
//  Created by Jeff Arena on 3/25/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectTTTableItem.h"
#import <Three20UI/Three20UI+Additions.h>
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitThree20


@implementation RKManagedObjectTTTableItem

@synthesize managedObject = _managedObject;

+ (id)itemWithManagedObject:(NSManagedObject*)managedObject {
	RKManagedObjectTTTableItem* item = [[[self alloc] init] autorelease];
	item.managedObject = managedObject;
	item.URL = [managedObject URLValueWithName:@"show"];
	return item;
}

- (id)init {
	if (self = [super init]) {
		_managedObject = nil;
	}
	return self;
}

- (void)dealloc {
	[_managedObject release];
	_managedObject = nil;
	[super dealloc];
}


#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder*)decoder {
    if (self = [super initWithCoder:decoder]) {
        self.managedObject = [decoder decodeObjectForKey:@"managedObject"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder {
    [super encodeWithCoder:encoder];
    if (self.managedObject) {
		[encoder encodeObject:self.managedObject forKey:@"managedObject"];
    }
}

@end
