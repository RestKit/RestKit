//
//  RKRequestQueueExample.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import "RKCatalog.h"

@interface RKRequestQueueExample : UIViewController <RKRequestQueueDelegate, RKRequestDelegate>

@property (nonatomic, retain) RKRequestQueue *requestQueue;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;

- (IBAction)sendRequest;
- (IBAction)queueRequests;
    
@end
