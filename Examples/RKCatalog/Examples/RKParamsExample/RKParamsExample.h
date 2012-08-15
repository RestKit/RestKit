//
//  RKParamsExample.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKCatalog.h"

@interface RKParamsExample : UIViewController <RKRequestDelegate> {
    RKClient *_client;
    UIProgressView *_progressView;
    UIActivityIndicatorView *_activityIndicatorView;
    UIImageView *_imageView;
    UIButton *_uploadButton;
    UILabel *_statusLabel;
}

@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIButton *uploadButton;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;

- (IBAction)uploadButtonWasTouched:(id)sender;

@end
