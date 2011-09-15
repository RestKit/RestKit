//
//  RKRequestSerialization.m
//  RestKit
//
//  Created by Blake Watters on 5/18/11.
//  Copyright 2011 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
