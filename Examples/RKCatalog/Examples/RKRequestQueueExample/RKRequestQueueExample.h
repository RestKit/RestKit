//
//  RKRequestQueueExample.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKCatalog.h"

@interface RKRequestQueueExample : UIViewController <RKRequestQueueDelegate, RKRequestDelegate>

@property (nonatomic, retain) RKRequestQueue *requestQueue;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;

- (IBAction)sendRequest;
- (IBAction)queueRequests;

@end
