//
//  RKReachabilityExample.h
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKCatalog.h"

@interface RKReachabilityExample : UIViewController {
    RKReachabilityObserver* _observer;
    UILabel* _statusLabel;
}

@property (nonatomic, retain) IBOutlet UILabel* statusLabel;

@end
