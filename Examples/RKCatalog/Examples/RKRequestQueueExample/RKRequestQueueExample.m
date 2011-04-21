//
//  RKRequestQueueExample.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RKRequestQueueExample.h"

@implementation RKRequestQueueExample

@synthesize queue = _queue;
@synthesize statusLabel = _statusLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        RKClient* client = [RKClient clientWithBaseURL:gRKCatalogBaseURL];
        [RKClient setSharedClient:client];
        
        // Ask RestKit to spin the network activity indicator for us
        [RKRequestQueue sharedQueue].delegate = self;
        [RKRequestQueue sharedQueue].showsNetworkActivityIndicatorWhenBusy = YES;
    }
    
    return self;
}

// We have been dismissed -- clean up any open requests
- (void)dealloc {
    [[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];
    [_queue release];
    
    [super dealloc];
}

// We have been obscured -- cancel any pending requests
- (void)viewWillDisappear:(BOOL)animated {
    [[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];
}

- (IBAction)sendRequest {
    /**
     * Ask RKClient to load us some data. This causes an RKRequest object to be created
     * transparently pushed onto the RKRequestQueue sharedQueue instance
     */
    [[RKClient sharedClient] get:@"/RKRequestQueueExample" delegate:self];
}

- (IBAction)queueRequests {
    RKRequestQueue* queue = [[RKRequestQueue alloc] init];
    queue.delegate = self;
    queue.concurrentRequestsLimit = 1;
    queue.showsNetworkActivityIndicatorWhenBusy = YES;
    
    // Queue up 4 requests
    [queue addRequest:[[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample" delegate:self]];
    [queue addRequest:[[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample" delegate:self]];
    [queue addRequest:[[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample" delegate:self]];
    [queue addRequest:[[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample" delegate:self]];
    
    // Start processing!
    [queue start];
    
    // Manage memory for our ad-hoc queue
    self.queue = queue;
    [queue release];
}

- (void)requestQueue:(RKRequestQueue *)queue didSendRequest:(RKRequest *)request {
    _statusLabel.text = [NSString stringWithFormat:@"RKRequestQueue %@ sharedQueue is current loading %d of %d requests", 
                         queue, [queue loadingCount], [queue count]];
}

- (void)requestQueueDidBeginLoading:(RKRequestQueue *)queue {
    _statusLabel.text = [NSString stringWithFormat:@"Queue %@ Began Loading...", queue];
}

- (void)requestQueueDidFinishLoading:(RKRequestQueue *)queue {
    _statusLabel.text = [NSString stringWithFormat:@"Queue %@ Finished Loading...", queue];
}

@end
