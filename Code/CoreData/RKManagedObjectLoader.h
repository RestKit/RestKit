//
//  RKManagedObjectLoader.h
//  RestKit
//
//  Created by Blake Watters on 2/13/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "../ObjectMapping/RKObjectLoader.h"

// Handles object loads when Core Data is being utilized
@interface RKManagedObjectLoader : RKObjectLoader {
    NSManagedObjectID* _targetObjectID;	
}

@end
