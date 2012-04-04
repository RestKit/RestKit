//
//  RKAuthenticationExample.h
//  RKCatalog
//
//  Created by Blake Watters on 9/27/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RKCatalog.h"

@interface RKAuthenticationExample : UIViewController <RKRequestDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, retain) RKRequest *authenticatedRequest;
@property (nonatomic, retain) IBOutlet UITextField  *URLTextField;
@property (nonatomic, retain) IBOutlet UITextField  *usernameTextField;
@property (nonatomic, retain) IBOutlet UITextField  *passwordTextField;
@property (nonatomic, retain) IBOutlet UIPickerView *authenticationTypePickerView;

- (IBAction)sendRequest;

@end
