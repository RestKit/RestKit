//
//  RKValueTransformers.h
//  RestKit
//
//  Created by Blake Watters on 11/26/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RKDateToStringValueTransformer : NSValueTransformer

@property (nonatomic, copy) NSFormatter *dateToStringFormatter;
@property (nonatomic, copy) NSArray *stringToDateFormatters;

- (id)initWithDateToStringFormatter:(NSFormatter *)dateToStringFormatter stringToDateFormatters:(NSArray *)stringToDateFormatters;

@end
