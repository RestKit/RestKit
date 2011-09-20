//
//  RKRequestQueueExample.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKCatalog.h"

@interface RKRequestQueueExample : UIViewController <RKRequestQueueDelegate, RKRequestDelegate> {
    UILabel* _statusLabel;
    RKRequestQueue* _queue;
}

@property (nonatomic, retain) RKRequestQueue* queue;
@property (nonatomic, retain) IBOutlet UILabel* statusLabel;

- (IBAction)sendRequest;
- (IBAction)queueRequests;
    
@end
