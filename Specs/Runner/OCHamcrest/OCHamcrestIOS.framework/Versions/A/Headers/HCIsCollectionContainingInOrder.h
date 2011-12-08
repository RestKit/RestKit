//
//  OCHamcrest - HCIsCollectionContainingInOrder.h
//  Copyright 2011 hamcrest.org. See LICENSE.txt
//
//  Created by: Jon Reid
//

#import <OCHamcrestIOS/HCBaseMatcher.h>


@interface HCIsCollectionContainingInOrder : HCBaseMatcher
{
    NSArray *matchers;
}

+ (id)isCollectionContainingInOrder:(NSArray *)itemMatchers;
- (id)initWithMatchers:(NSArray *)itemMatchers;

@end


OBJC_EXPORT id<HCMatcher> HC_contains(id itemMatch, ...) NS_REQUIRES_NIL_TERMINATION;

/**
    contains(firstMatcher, ...) -
    Matches if collection's elements satisfy a given list of matchers, in order.
    
    @param firstMatcher,...  A comma-separated list of matchers ending with @c nil.
    
    This matcher iterates the evaluated collection and a given list of matchers, seeing if each
    element satisfies its corresponding matcher.
    
    Any argument that is not a matcher is implicitly wrapped in an @ref equalTo matcher to check for
    equality.
    
    (In the event of a name clash, don't \#define @c HC_SHORTHAND and use the synonym
    @c HC_contains instead.)

    @ingroup collection_matchers
 */
#ifdef HC_SHORTHAND
    #define contains HC_contains
#endif
