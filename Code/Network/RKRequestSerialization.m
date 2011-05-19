//
//  RKRequestSerialization.m
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKRequestSerialization.h"

@implementation RKRequestSerialization

@synthesize data = _data;
@synthesize MIMEType = _MIMEType;

- (id)initWithData:(NSData*)data MIMEType:(NSString*)MIMEType {
    NSAssert(data, @"Cannot create a request serialization without Data");
    NSAssert(MIMEType, @"Cannot create a request serialization without a MIME Type");
    
    self = [super init];
    if (self) {
        _data = [data retain];
        _MIMEType = [MIMEType retain];
    }
    
    return self;
}

+ (id)serializationWithData:(NSData*)data MIMEType:(NSString*)MIMEType {
    return [[[RKRequestSerialization alloc] initWithData:data MIMEType:MIMEType] autorelease];
}

- (void)dealloc {
    [_data release];
    [_MIMEType release];
    
    [super dealloc];
}

- (NSString*)HTTPHeaderValueForContentType {
    return self.MIMEType;
}

- (NSData*)HTTPBody {
    return self.data;
}

- (NSUInteger)HTTPHeaderValueForContentLength {
    return [self.data length];
}

@end
