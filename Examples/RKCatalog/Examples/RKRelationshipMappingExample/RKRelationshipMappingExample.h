//
//  RKRelationshipMappingExample.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKCatalog.h"
#import "Project.h"

@interface RKRelationshipMappingExample : UITableViewController <RKObjectLoaderDelegate, UITableViewDelegate> {
    Project* _selectedProject;
    NSArray* _objects;
}

@end
