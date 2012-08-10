//  RKRefreshGestureRecognizer.m
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

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "RKRefreshGestureRecognizer.h"

NSString * const RKRefreshGestureAnimationKey       = @"RKRefreshGestureAnimationKey";
NSString * const RKRefreshResetGestureAnimationKey  = @"RKRefreshResetGestureAnimationKey";
static CGFloat const kFlipArrowAnimationTime = 0.18f;
static CGFloat const kDefaultTriggerViewHeight = 64.f;

@interface RKRefreshGestureRecognizer ()

- (CABasicAnimation *)triggeredAnimation;
- (CABasicAnimation *)idlingAnimation;

@property (nonatomic, retain, readwrite) RKRefreshTriggerView *triggerView;
@property (nonatomic, assign) BOOL isBoundToScrollView;
@property (nonatomic, retain) NSDateFormatter *dateFormatter;

@end

@implementation RKRefreshGestureRecognizer
#pragma mark - Synthesizers
@synthesize triggerView = _triggerView;
@synthesize refreshState = _refreshState;
@synthesize isBoundToScrollView = _isBoundToScrollView;
@synthesize dateFormatter = _dateFormatter;

#pragma mark - Life Cycle
- (id)initWithTarget:(id)target action:(SEL)action
{

    self = [super initWithTarget:target action:action];
    if (self) {
        _triggerView = [[RKRefreshTriggerView alloc] initWithFrame:CGRectZero];
        _triggerView.titleLabel.text = NSLocalizedString(@"Pull down to refresh...", @"Pull down to refresh status");
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [self addObserver:self forKeyPath:@"view" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"view"];
    if (self.triggerView)
        [self.triggerView removeFromSuperview];
    self.triggerView = nil;
    [super dealloc];
}

#pragma mark - Utilities

- (void)refreshLastUpdatedDate
{

    SEL lastUpdatedSelector = @selector(pullToRefreshDataSourceLastUpdated:);
    if (self.scrollView.delegate && [self.scrollView.delegate respondsToSelector:lastUpdatedSelector]) {
        NSDate *date = [self.scrollView.delegate performSelector:lastUpdatedSelector withObject:self];
        if (!date)
            return;
        NSString *lastUpdatedText = [NSString stringWithFormat:@"Last Updated: %@", [self.dateFormatter stringFromDate:date]];
        self.triggerView.lastUpdatedLabel.text = lastUpdatedText;

    } else {
        self.triggerView.lastUpdatedLabel.text = nil;
    }

}

- (void)setRefreshState:(RKRefreshState)refreshState
{
    if (refreshState == _refreshState)
        return;

    __block UIScrollView *bScrollView = self.scrollView;

    switch (refreshState) {

        case RKRefreshTriggered: {
            if (![self.triggerView.arrowView.layer animationForKey:RKRefreshGestureAnimationKey])
                [self.triggerView.arrowView.layer addAnimation:[self triggeredAnimation] forKey:RKRefreshGestureAnimationKey];
            self.triggerView.titleLabel.text = NSLocalizedString(@"Release to refresh...", @"Release to refresh status");
        }
            break;

        case RKRefreshIdle: {
            if (_refreshState == RKRefreshLoading) {
                [UIView animateWithDuration:0.2 animations:^{
                    bScrollView.contentInset = UIEdgeInsetsMake(0,
                                                                bScrollView.contentInset.left,
                                                                bScrollView.contentInset.bottom,
                                                                bScrollView.contentInset.right);
                }];

                [self.triggerView.arrowView.layer removeAllAnimations];
                [self.triggerView.activityView removeFromSuperview];
                [self.triggerView.activityView stopAnimating];
                [self.triggerView addSubview:self.triggerView.arrowView];

            } else if (_refreshState == RKRefreshTriggered) {
                if ([self.triggerView.arrowView.layer animationForKey:RKRefreshGestureAnimationKey]) {
                    [self.triggerView.arrowView.layer addAnimation:[self idlingAnimation] forKey:RKRefreshResetGestureAnimationKey];
                }
            }
            [self refreshLastUpdatedDate];
            self.triggerView.titleLabel.text = NSLocalizedString(@"Pull down to refresh...", @"Pull down to refresh status");
        }
            break;

        case RKRefreshLoading: {
            [UIView animateWithDuration:0.2 animations:^{
                bScrollView.contentInset = UIEdgeInsetsMake(kDefaultTriggerViewHeight,
                                                            bScrollView.contentInset.left,
                                                            bScrollView.contentInset.bottom,
                                                            bScrollView.contentInset.right);
            }];
            self.triggerView.titleLabel.text = NSLocalizedString(@"Loading...", @"Loading Status");
            [self.triggerView.arrowView removeFromSuperview];
            [self.triggerView addSubview:self.triggerView.activityView];
            [self.triggerView.activityView startAnimating];
        }
            break;
    }

    _refreshState = refreshState;
}

- (CABasicAnimation *)triggeredAnimation
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.duration = kFlipArrowAnimationTime;
    animation.toValue = [NSNumber numberWithDouble:M_PI];
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    return animation;
}

- (CABasicAnimation *)idlingAnimation
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.delegate = self;
    animation.duration = kFlipArrowAnimationTime;
    animation.toValue = [NSNumber numberWithDouble:0];
    animation.removedOnCompletion = YES;
    return animation;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self.triggerView.arrowView.layer removeAllAnimations];
}

- (UIScrollView *)scrollView
{
    return (UIScrollView *)self.view;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id obj = [object valueForKeyPath:keyPath];
    if (NO == [obj isKindOfClass:[UIScrollView class]]) {
        self.isBoundToScrollView = NO;
        return;
    }
    self.isBoundToScrollView = YES;
    self.triggerView.frame = CGRectMake(0, -kDefaultTriggerViewHeight, CGRectGetWidth(self.view.frame), kDefaultTriggerViewHeight);
    [obj addSubview:self.triggerView];
}

#pragma mark UIGestureRecognizer
- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
    return NO;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
    return NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.isBoundToScrollView)
        return;
    if (self.state < UIGestureRecognizerStateBegan) {
        self.state = UIGestureRecognizerStateBegan;
    }

    if (self.scrollView.contentOffset.y < -kDefaultTriggerViewHeight) {
        self.refreshState   = RKRefreshTriggered;
        self.state          = UIGestureRecognizerStateChanged;
    } else if (self.state != UIGestureRecognizerStateRecognized) {
        self.refreshState   = RKRefreshIdle;
        self.state          = UIGestureRecognizerStateChanged;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.isBoundToScrollView) {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    if (self.refreshState == RKRefreshTriggered) {
        self.refreshState = RKRefreshLoading;
        self.state = UIGestureRecognizerStateRecognized;
        return;
    }
    self.state = UIGestureRecognizerStateCancelled;
    self.refreshState = RKRefreshIdle;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
        self.state = UIGestureRecognizerStateCancelled;
}

@end

#endif
