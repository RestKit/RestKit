//
//  UIViewController+RKLoading.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/12/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

// TODO: Why not move this into a controller and inherit instead of using categories?
@interface UIViewController (RKLoading) <RKRequestDelegate>

@end
