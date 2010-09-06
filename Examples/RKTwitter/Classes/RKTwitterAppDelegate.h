//
//  RKTwitterAppDelegate.h
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright Two Toasters 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RKTwitterViewController;

@interface RKTwitterAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    RKTwitterViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet RKTwitterViewController *viewController;

@end

