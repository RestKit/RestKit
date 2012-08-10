//  RKRefreshGestureRecognizer.h
//  RestKit
//
//  Based on PHRefreshTriggerView by Pier-Olivier Thibault
//  Adapted by Gregory S. Combs on 1/13/2012
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
#import "RKRefreshTriggerView.h"

typedef enum {
    RKRefreshIdle = 0,
    RKRefreshTriggered,
    RKRefreshLoading
} RKRefreshState;

@protocol RKRefreshTriggerProtocol <NSObject>
@optional
- (NSDate *)pullToRefreshDataSourceLastUpdated:(UIGestureRecognizer *)recognizer;
- (BOOL)pullToRefreshDataSourceIsLoading:(UIGestureRecognizer *)recognizer;
@end

@interface RKRefreshGestureRecognizer : UIGestureRecognizer
@property (nonatomic, assign) RKRefreshState refreshState; // You can force a gesture state by modifying this value.
@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly, retain) RKRefreshTriggerView *triggerView;
@end

#endif
