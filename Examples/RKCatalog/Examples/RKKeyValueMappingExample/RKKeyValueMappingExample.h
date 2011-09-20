//
//  RKKeyValueMappingExample.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKCatalog.h"

@interface RKKeyValueMappingExample : UIViewController <RKObjectLoaderDelegate> {
    UILabel* _infoLabel;
}

@property (nonatomic, retain) IBOutlet UILabel* infoLabel;

@end
