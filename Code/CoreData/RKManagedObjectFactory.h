//
//  RKManagedObjectFactory.h
//  RestKit
//
//  Created by Blake Watters on 5/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "../ObjectMapping/RKObjectFactory.h"
#import "RKManagedObjectStore.h"

/**
 An object factory capable of intializing Core Data backed managed objects.
 Also capable of finding existing objects that are identified by a particular
 set of mappable data.
 */
@interface RKManagedObjectFactory : NSObject <RKObjectFactory> {
    RKManagedObjectStore* _objectStore;
}

+ (id)objectFactoryWithObjectStore:(RKManagedObjectStore*)objectStore;

@end
