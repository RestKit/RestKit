//
//  RKAbstractTableController_Internals.h
//  RestKit
//
//  Created by Jeff Arena on 8/11/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

#import <Foundation/Foundation.h>
#import "RKRefreshGestureRecognizer.h"

@interface RKAbstractTableController () <RKObjectLoaderDelegate, RKRefreshTriggerProtocol>

@property (nonatomic, readwrite, assign) UITableView* tableView;
@property (nonatomic, readwrite, assign) UIViewController* viewController;
@property (nonatomic, readwrite, retain) RKObjectLoader* objectLoader;
@property (nonatomic, readwrite, assign) BOOL loading;
@property (nonatomic, readwrite, assign) BOOL loaded;
@property (nonatomic, readwrite, assign) BOOL empty;
@property (nonatomic, readwrite, assign) BOOL online;
@property (nonatomic, readwrite, retain) NSError* error;
@property (nonatomic, readwrite, retain) NSMutableArray* headerItems;
@property (nonatomic, readwrite, retain) NSMutableArray* footerItems;

@property (nonatomic, readonly) UIView *tableOverlayView;
@property (nonatomic, readonly) UIImageView *stateOverlayImageView;
@property (nonatomic, readonly) RKCache *cache;

/**
 Must be invoked when the table controller has finished loading.

 Responsible for finalizing loading, empty, and loaded states
 and cleaning up the table overlay view.
 */
- (void)didFinishLoad;
- (void)updateOfflineImageForOnlineState:(BOOL)isOnline;

#pragma mark - Table View Overlay

- (void)addToOverlayView:(UIView *)view modally:(BOOL)modally;
- (void)resetOverlayView;
- (void)addSubviewOverTableView:(UIView *)view;
- (BOOL)removeImageFromOverlay:(UIImage *)image;
- (void)showImageInOverlay:(UIImage *)image;
- (void)removeImageOverlay;

#pragma mark - Pull to Refresh Private Methods

- (void)pullToRefreshStateChanged:(UIGestureRecognizer *)gesture;
- (void)resetPullToRefreshRecognizer;


@end
