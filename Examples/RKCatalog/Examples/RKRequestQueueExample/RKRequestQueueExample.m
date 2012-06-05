//
//  RKRequestQueueExample.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RKRequestQueueExample.h"

@implementation RKRequestQueueExample

@synthesize requestQueue;
@synthesize statusLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        RKClient *client = [RKClient clientWithBaseURL:gRKCatalogBaseURL];
        [RKClient setSharedClient:client];

        // Ask RestKit to spin the network activity indicator for us
        client.requestQueue.delegate = self;
        client.requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;
    }

    return self;
}

// We have been dismissed -- clean up any open requests
- (void)dealloc
{
    [[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
    [requestQueue cancelAllRequests];
    [requestQueue release];
    requestQueue = nil;

    [super dealloc];
}

// We have been obscured -- cancel any pending requests
- (void)viewWillDisappear:(BOOL)animated
{
    [[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
}

- (IBAction)sendRequest
{
    /**
     * Ask RKClient to load us some data. This causes an RKRequest object to be created
     * transparently pushed onto the RKClient's RKRequestQueue instance
     */
    [[RKClient sharedClient] get:@"/RKRequestQueueExample" delegate:self];
}

- (IBAction)queueRequests
{
    RKRequestQueue *queue = [RKRequestQueue requestQueue];
    queue.delegate = self;
    queue.concurrentRequestsLimit = 1;
    queue.showsNetworkActivityIndicatorWhenBusy = YES;

    // Queue up 4 requests
    RKRequest *request = [[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample"];
    request.delegate = self;
    [queue addRequest:request];

    request = [[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample"];
    request.delegate = self;
    [queue addRequest:request];

    request = [[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample"];
    request.delegate = self;
    [queue addRequest:request];

    request = [[RKClient sharedClient] requestWithResourcePath:@"/RKRequestQueueExample"];
    request.delegate = self;
    [queue addRequest:request];

    // Start processing!
    [queue start];
    self.requestQueue = queue;
}

- (void)requestQueue:(RKRequestQueue *)queue didSendRequest:(RKRequest *)request
{
    statusLabel.text = [NSString stringWithFormat:@"RKRequestQueue %@ is current loading %d of %d requests",
                         queue, [queue loadingCount], [queue count]];
}

- (void)requestQueueDidBeginLoading:(RKRequestQueue *)queue
{
    statusLabel.text = [NSString stringWithFormat:@"Queue %@ Began Loading...", queue];
}

- (void)requestQueueDidFinishLoading:(RKRequestQueue *)queue
{
    statusLabel.text = [NSString stringWithFormat:@"Queue %@ Finished Loading...", queue];
}

@end
