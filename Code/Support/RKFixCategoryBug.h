//
//  RKCategoryFix.h
//  RestKit
//
//  Created by Blake Watters on 9/1/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
//

#ifndef RestKit_RKCategoryFix_h
#define RestKit_RKCategoryFix_h

/**
 Add this macro before each category implementation, so we don't have to use
 -all_load or -force_load to load object files from static libraries that only contain
 categories and no classes.
 See http://developer.apple.com/library/mac/#qa/qa2006/qa1490.html for more info.
 
 Shamelessly borrowed from Three20
 */
#define RK_FIX_CATEGORY_BUG(name) @interface RK_FIX_CATEGORY_BUG##name @end \
@implementation RK_FIX_CATEGORY_BUG##name @end

#endif
