//
// Copyright 2009-2010 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * A constant denoting that a corner should be rounded.
 * @const -1
 */
extern const CGFloat ttkRounded;

/**
 * Deprecated macros for common constants.
 */
#define TT_ROUNDED                    ttkRounded

///////////////////////////////////////////////////////////////////////////////////////////////////
// Color helpers

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 \
alpha:(a)]

#define HSVCOLOR(h,s,v) [UIColor colorWithHue:(h) saturation:(s) value:(v) alpha:1]
#define HSVACOLOR(h,s,v,a) [UIColor colorWithHue:(h) saturation:(s) value:(v) alpha:(a)]

#define RGBA(r,g,b,a) (r)/255.0, (g)/255.0, (b)/255.0, (a)

///////////////////////////////////////////////////////////////////////////////////////////////////
// Style helpers

#define TTSTYLE(_SELECTOR) [[TTStyleSheet globalStyleSheet] styleWithSelector:@#_SELECTOR]

#define TTSTYLESTATE(_SELECTOR, _STATE) [[TTStyleSheet globalStyleSheet] \
                                           styleWithSelector:@#_SELECTOR forState:_STATE]

#define TTSTYLESHEET ((id)[TTStyleSheet globalStyleSheet])

#define TTSTYLEVAR(_VARNAME) [TTSTYLESHEET _VARNAME]
