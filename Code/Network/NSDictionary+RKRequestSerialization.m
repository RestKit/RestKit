//
//  NSDictionary+RKRequestSerialization.m
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "NSDictionary+RKRequestSerialization.h"

/**
 * private helper function to convert any object to its string representation
 * @private
 */
static NSString *toString(id object) {
	return [NSString stringWithFormat: @"%@", object];
}

/**
 * private helper function to convert string to UTF-8 and URL encode it
 * @private
 */
static NSString *urlEncode(id object) {
	NSString *string = toString(object);
	NSString *encodedString = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,
																				 (CFStringRef)string,
																				 NULL,
																				 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
																				 kCFStringEncodingUTF8);
	return [encodedString autorelease];
}


@implementation NSDictionary (RKRequestSerialization)

// TODO: Need a more robust, recursive implementation of URLEncoding...
- (NSString*)URLEncodedString {
	NSMutableArray *parts = [NSMutableArray array];
	for (id key in self) {
		id value = [self objectForKey:key];
		if ([value isKindOfClass:[NSArray class]]) {
			for (id item in value) {
                if ([item isKindOfClass:[NSDictionary class]] || [item isKindOfClass:[NSMutableDictionary class]]) {
                    // Handle nested object one level deep
                    for( NSString *nKey in [item allKeys] ) {
                        id nValue = [item objectForKey:nKey];
                        NSString *part = [NSString stringWithFormat: @"%@[][%@]=%@",
                                          urlEncode(key), urlEncode(nKey), urlEncode(nValue)];
                        [parts addObject:part];
                    }
                } else {
                    // Stringify
                    NSString *part = [NSString stringWithFormat: @"%@[]=%@",
                                      urlEncode(key), urlEncode(item)];
                    [parts addObject:part];
                }
			}
		} else if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]]) {
            for ( NSString *nKey in [value allKeys] ) {
                id nValue = [value objectForKey:nKey];
                NSString *part = [NSString stringWithFormat: @"%@[%@]=%@",
                                  urlEncode(key), urlEncode(nKey), urlEncode(nValue)];
                [parts addObject:part];
            }
        } else {
			NSString *part = [NSString stringWithFormat: @"%@=%@",
							  urlEncode(key), urlEncode(value)];
			[parts addObject:part];
		}
	}

	return [parts componentsJoinedByString: @"&"];
}

- (NSString*)HTTPHeaderValueForContentType {
	return @"application/x-www-form-urlencoded";
}

- (NSData*)HTTPBody {
	return [[self URLEncodedString] dataUsingEncoding:NSUTF8StringEncoding];
}

@end
