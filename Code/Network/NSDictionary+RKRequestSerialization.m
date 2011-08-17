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

- (void)URLEncodePart:(NSMutableArray*)parts path:(NSString*)path value:(id)value {
    [parts addObject:[NSString stringWithFormat: @"%@=%@", path, urlEncode(value)]];
}

- (void)URLEncodeParts:(NSMutableArray*)parts path:(NSString*)inPath {
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop)
    {
        NSString* path = inPath ? [inPath stringByAppendingFormat:@"[%@]", urlEncode(key)] : urlEncode(key);
        if( [value isKindOfClass:[NSArray class]] )
        {
			for( id item in value )
            {
                [self URLEncodePart:parts path:[path stringByAppendingString:@"[]"] value:item];
            }
        }
        else if([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSMutableDictionary class]])
        {
            [value URLEncodeParts:parts path:path];
        }
        else
        {
            [self URLEncodePart:parts path:path value:value];
        }
    }];
}

- (NSString*)URLEncodedString {
    NSMutableArray* parts = [NSMutableArray array];
    [self URLEncodeParts:parts path:nil];
    return [parts componentsJoinedByString:@"&"];
}

- (NSString*)HTTPHeaderValueForContentType {
	return @"application/x-www-form-urlencoded";
}

- (NSData*)HTTPBody {
	return [[self URLEncodedString] dataUsingEncoding:NSUTF8StringEncoding];
}

@end
