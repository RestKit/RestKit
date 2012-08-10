//
//  RKRelationshipMappingExample.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKCatalog.h"
#import "Project.h"

@interface RKRelationshipMappingExample : UITableViewController <RKObjectLoaderDelegate, UITableViewDelegate> {
    Project *_selectedProject;
    NSArray *_objects;
}

@end
