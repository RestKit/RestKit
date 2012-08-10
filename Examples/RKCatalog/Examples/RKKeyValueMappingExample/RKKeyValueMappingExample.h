//
//  RKKeyValueMappingExample.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKCatalog.h"

@interface RKKeyValueMappingExample : UIViewController <RKObjectLoaderDelegate> {
    UILabel *_infoLabel;
}

@property (nonatomic, retain) IBOutlet UILabel *infoLabel;

@end
