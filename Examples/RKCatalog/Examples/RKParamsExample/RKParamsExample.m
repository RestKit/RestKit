//
//  RKParamsExample.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKParamsExample.h"

@implementation RKParamsExample

@synthesize progressView = _progressView;
@synthesize activityIndicatorView = _activityIndicatorView;
@synthesize imageView = _imageView;
@synthesize uploadButton = _uploadButton;
@synthesize statusLabel = _statusLabel;

- (void)dealloc
{
    [RKClient setSharedClient:nil];
    [_client release];
    [super dealloc];
}

- (void)viewDidLoad
{
    _client = [[RKClient alloc] initWithBaseURL:gRKCatalogBaseURL];
}

- (IBAction)uploadButtonWasTouched:(id)sender
{
    RKParams *params = [RKParams params];

    // Attach the Image from Image View
    NSLog(@"Got image: %@", [_imageView image]);
    NSData *imageData = UIImagePNGRepresentation([_imageView image]);
    [params setData:imageData MIMEType:@"image/png" forParam:@"image1"];

    // Attach an Image from the App Bundle
    UIImage *image = [UIImage imageNamed:@"RestKit.png"];
    imageData = UIImagePNGRepresentation(image);
    [params setData:imageData MIMEType:@"image/png" forParam:@"image2"];

    // Log info about the serialization
    NSLog(@"RKParams HTTPHeaderValueForContentType = %@", [params HTTPHeaderValueForContentType]);
    NSLog(@"RKParams HTTPHeaderValueForContentLength = %d", [params HTTPHeaderValueForContentLength]);

    // Send it for processing!
    [_client post:@"/RKParamsExample" params:params delegate:self];
}

- (void)requestDidStartLoad:(RKRequest *)request
{
    _uploadButton.enabled = NO;
    [_activityIndicatorView startAnimating];
}

- (void)request:(RKRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    _progressView.progress = (totalBytesWritten / totalBytesExpectedToWrite) * 100.0;
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    _uploadButton.enabled = YES;
    [_activityIndicatorView stopAnimating];

    if ([response isOK]) {
        _statusLabel.text = @"Upload Successful!";
        _statusLabel.textColor = [UIColor greenColor];
    } else {
        _statusLabel.text = [NSString stringWithFormat:@"Upload failed with status code: %d", [response statusCode]];
        _statusLabel.textColor = [UIColor redColor];
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    _uploadButton.enabled = YES;
    [_activityIndicatorView stopAnimating];
    _progressView.progress = 0.0;

    _statusLabel.text = [NSString stringWithFormat:@"Upload failed with error: %@", [error localizedDescription]];
    _statusLabel.textColor = [UIColor redColor];
}

@end
