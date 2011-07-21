//
//  RKAlert.h
//  RestKit
//
//  Created by Blake Watters on 4/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Presents an alert dialog with the specified message
 */
void RKAlert(NSString* message);

/**
 * Presents an alert dialog with the specified message and title
 */
void RKAlertWithTitle(NSString* message, NSString* title);
