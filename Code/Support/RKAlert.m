//
//  RKAlert.m
//  RestKit
//
//  Created by Blake Watters on 4/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import "RKAlert.h"

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
#else
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:message];
     [alert setInformativeText:message];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];	
    [alert runModal];
    [alert release];
#endif    
}
