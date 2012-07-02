//
//  RKBackgroundRequestExample.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKCatalog.h"

@interface RKBackgroundRequestExample : UIViewController <RKRequestDelegate> {
    UIButton *_sendButton;
    UISegmentedControl *_segmentedControl;
    UILabel *_statusLabel;
}

@property (nonatomic, retain) IBOutlet UIButton *sendButton;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;

- (IBAction)sendRequest;

@end
