//
//  RKReachabilityExample.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKCatalog.h"

@interface RKReachabilityExample : UIViewController {
    RKReachabilityObserver *_observer;
    UILabel *_statusLabel;
    UILabel *_flagsLabel;
}

@property (nonatomic, retain) RKReachabilityObserver *observer;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UILabel *flagsLabel;

@end
