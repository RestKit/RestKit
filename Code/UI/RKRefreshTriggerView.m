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
// TODO: Figure out how to automatically install RestKitResources.bundle and use that bundle path for arrow images

#import "RKRefreshTriggerView.h"

#if TARGET_OS_IPHONE

#define DEFAULT_REFRESH_TITLE_FONT      [UIFont boldSystemFontOfSize:13.0f]
#define DEFAULT_REFRESH_TITLE_COLOR     [UIColor darkGrayColor]
#define DEFAULT_REFRESH_UPDATED_FONT    [UIFont systemFontOfSize:12.0f]
#define DEFAULT_REFRESH_UPDATED_COLOR   [UIColor lightGrayColor]
#define DEFAULT_REFRESH_ARROW_IMAGE     [UIImage imageNamed:@"blueArrow"]
#define DEFAULT_REFRESH_ACTIVITY_STYLE  UIActivityIndicatorViewStyleWhite

@interface RKRefreshTriggerView ()
@end

@implementation RKRefreshTriggerView
@synthesize titleLabel      = _titleLabel;
@synthesize activityView    = _activityView;
@synthesize arrowView       = _arrowView;
@synthesize lastUpdatedLabel = _lastUpdatedLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor clearColor];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _titleLabel.textAlignment = UITextAlignmentCenter;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = DEFAULT_REFRESH_TITLE_FONT;
        _titleLabel.textColor = DEFAULT_REFRESH_TITLE_COLOR;
        [self addSubview:_titleLabel];

        _lastUpdatedLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _lastUpdatedLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _lastUpdatedLabel.backgroundColor = [UIColor clearColor];
        _lastUpdatedLabel.textAlignment = UITextAlignmentCenter;
        _lastUpdatedLabel.font = DEFAULT_REFRESH_UPDATED_FONT;
        _lastUpdatedLabel.textColor = DEFAULT_REFRESH_UPDATED_COLOR;
        [self addSubview:_lastUpdatedLabel];

        _arrowView = [[UIImageView alloc] initWithImage:DEFAULT_REFRESH_ARROW_IMAGE];
        _arrowView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_arrowView];

        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:DEFAULT_REFRESH_ACTIVITY_STYLE];
        _activityView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    }
    return self;
}


- (void)dealloc
{
    self.titleLabel = nil;
    self.arrowView  = nil;
    self.activityView = nil;
    self.lastUpdatedLabel = nil;
    [super dealloc];
}


- (void)layoutSubviews
{
    CGPoint imageCenter = CGPointMake(30, CGRectGetMidY(self.bounds));
    self.arrowView.center = imageCenter;
    self.arrowView.frame = CGRectIntegral(self.arrowView.frame);
    self.activityView.center = imageCenter;
    self.titleLabel.frame = CGRectIntegral(CGRectMake(0.0f, (CGRectGetHeight(self.bounds) * .25f), CGRectGetWidth(self.bounds), 20.0f));
    self.lastUpdatedLabel.frame = CGRectOffset(self.titleLabel.frame, 0.f, 18.f);
}

#ifdef UI_APPEARANCE_SELECTOR

#pragma mark - Proxy Accessors for UIAppearance

- (UIImage *)arrowImage
{
    if (!self.arrowView)
        return DEFAULT_REFRESH_ARROW_IMAGE;
    return _arrowView.image;
}

- (void)setArrowImage:(UIImage *)image
{
    if (!self.arrowView)
        return;
    self.arrowView.image = image;
}

- (UIActivityIndicatorViewStyle)activityIndicatorStyle
{
    if (!self.activityView)
        return DEFAULT_REFRESH_ACTIVITY_STYLE;
    return self.activityView.activityIndicatorViewStyle;
}

- (void)setActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style
{
    if (!self.activityView)
        return;
    self.activityView.activityIndicatorViewStyle = style;
}

- (UIFont *)titleFont
{
    if (!self.titleLabel)
        return DEFAULT_REFRESH_TITLE_FONT;
    return self.titleLabel.font;
}

- (void)setTitleFont:(UIFont *)font
{
    if (!self.titleLabel)
        return;
    self.titleLabel.font = font;
}

- (UIColor *)titleColor
{
    if (!self.titleLabel)
        return DEFAULT_REFRESH_TITLE_COLOR;
    return self.titleLabel.textColor;
}

- (void)setTitleColor:(UIColor *)color
{
    if (!self.titleLabel)
        return;
    self.titleLabel.textColor = color;
}

- (UIFont *)lastUpdatedFont
{
    if (!self.lastUpdatedLabel)
        return DEFAULT_REFRESH_UPDATED_FONT;
    return self.lastUpdatedLabel.font;
}

- (void)setLastUpdatedFont:(UIFont *)font
{
    if (!self.lastUpdatedLabel)
        return;
    self.lastUpdatedLabel.font = font;
}

- (UIColor *)lastUpdatedColor
{
    if (!self.lastUpdatedLabel)
        return DEFAULT_REFRESH_UPDATED_COLOR;
    return self.lastUpdatedLabel.textColor;
}

- (void)setLastUpdatedColor:(UIColor *)color
{
    if (!self.lastUpdatedLabel)
        return;
    self.lastUpdatedLabel.textColor = color;
}

- (UIColor *)refreshBackgroundColor
{
    return self.backgroundColor;
}

- (void)setRefreshBackgroundColor:(UIColor *)backgroundColor
{
    [self setBackgroundColor:backgroundColor];
}
#endif

@end

#endif
