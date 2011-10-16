//
//  RKAlert.m
//  RestKit
//
//  Created by Blake Watters on 4/10/11.
//  Copyright 2011 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#endif

#import "RKAlert.h"
#import "RKLog.h"

void RKAlert(NSString* message) {
    RKAlertWithTitle(message, @"Alert");
}

void RKAlertWithTitle(NSString* message, NSString* title) {
#if TARGET_OS_IPHONE
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
#elif TARGET_OS_MAC
    Class alertClass = NSClassFromString(@"NSAlert");
    if (alertClass) {
        NSAlert *alert = [[alertClass alloc] init];
        [alert setMessageText:message];
         [alert setInformativeText:message];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];	
        [alert runModal];
        [alert release];
    } else {
        RKLogCritical(@"%@: %@", title, message);
    }
#elif TARGET_OS_UNIX
    RKLogCritical(@"%@: %@", title, message);
#endif    
}
