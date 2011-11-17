//
//  RKManagedObjectTTTableItem.h
//  RestKit
//
//  Created by Jeff Arena on 3/25/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import "../RestKit.h"

@interface RKManagedObjectTTTableItem : TTTableLinkedItem {
	NSManagedObject* _managedObject;
}

+ (id)itemWithManagedObject:(NSManagedObject*)managedObject;

@property (nonatomic, retain) NSManagedObject* managedObject;

@end
