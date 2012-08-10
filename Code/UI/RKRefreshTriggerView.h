//  RKRefreshTriggerView.h
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

@interface RKRefreshTriggerView : UIView <UIAppearanceContainer, UIAppearance>
@property (nonatomic, retain) UILabel *titleLabel;
@property (nonatomic, retain) UILabel *lastUpdatedLabel;
@property (nonatomic, retain) UIImageView *arrowView;
@property (nonatomic, retain) UIActivityIndicatorView *activityView;

#ifdef UI_APPEARANCE_SELECTOR
@property (nonatomic, assign) UIImage *arrowImage UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) UIActivityIndicatorViewStyle activityIndicatorStyle UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) UIFont *titleFont UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) UIColor *titleColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) UIFont *lastUpdatedFont UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) UIColor *lastUpdatedColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, retain) UIColor *refreshBackgroundColor UI_APPEARANCE_SELECTOR;
#endif

@end

#endif
