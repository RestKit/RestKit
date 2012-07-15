//
//  OCHamcrest - HCIsInstanceOf.h
//  Copyright 2011 hamcrest.org. See LICENSE.txt
//
//  Created by: Jon Reid
//

#import <OCHamcrestIOS/HCBaseMatcher.h>


@interface HCIsInstanceOf : HCBaseMatcher
{
    Class theClass;
}

+ (id)isInstanceOf:(Class)type;
- (id)initWithType:(Class)type;

@end


OBJC_EXPORT id<HCMatcher> HC_instanceOf(Class aClass);

/**
    instanceOf(aClass) -
    Matches if object is an instance of, or inherits from, a given class.

    @param aClass  The class to compare against as the expected class.

    This matcher checks whether the evaluated object is an instance of @a aClass or an instance of
    any class that inherits from @a aClass.

    Example:
    @li @ref instanceOf([NSString class])

    (In the event of a name clash, don't \#define @c HC_SHORTHAND and use the synonym
    @c HC_instanceOf instead.)

    @ingroup object_matchers
 */
#ifdef HC_SHORTHAND
    #define instanceOf HC_instanceOf
#endif
