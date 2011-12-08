//
//  OCHamcrest - HCStringStartsWith.h
//  Copyright 2011 hamcrest.org. See LICENSE.txt
//
//  Created by: Jon Reid
//

#import <OCHamcrestIOS/HCSubstringMatcher.h>


@interface HCStringStartsWith : HCSubstringMatcher

+ (id)stringStartsWith:(NSString *)aSubstring;

@end


OBJC_EXPORT id<HCMatcher> HC_startsWith(NSString *aSubstring);

/**
    startsWith(aString) -
    Matches if object is a string starting with a given string.

    @param aString  The string to search for. This value must not be @c nil.
    
    This matcher first checks whether the evaluated object is a string. If so, it checks if
    @a aString matches the beginning characters of the evaluated object.
    
    Example:
    
    @par
    @ref endsWith(@"foo")
    
    will match "foobar".

    (In the event of a name clash, don't \#define @c HC_SHORTHAND and use the synonym
    @c HC_startsWith instead.)

    @ingroup text_matchers
 */
#ifdef HC_SHORTHAND
    #define startsWith HC_startsWith
#endif
