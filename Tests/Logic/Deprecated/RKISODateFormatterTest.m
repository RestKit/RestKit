//
//  RKISODateFormatterTest.m
//  RestKit
//
//  Created by Blake Watters on 10/4/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKISO8601DateFormatter.h"

@interface RKISODateFormatterTest : RKTestCase

@end

@implementation RKISODateFormatterTest

- (void)testDateFormatterRespectsTimeZone
{
    RKISO8601DateFormatter *formatter = [[RKISO8601DateFormatter alloc] init];
    [formatter setIncludeTime:YES];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]]; // UTC
    
    NSDateFormatter *nsformatter = [[NSDateFormatter alloc] init];
    [nsformatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    [nsformatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]]; // UTC
    
    NSDate *date = [NSDate date];
    NSString *isoFormatted = [formatter stringFromDate:date];
    NSString *nsFormatted = [nsformatter stringFromDate:date];
    
    expect(isoFormatted).to.equal(nsFormatted);
}

@end
