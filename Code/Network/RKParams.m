//
//  RKParams.m
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 RestKit
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

#import "RKParams.h"
#import "RKLog.h"
#import "NSString+MD5.h"

// Need for iOS 5 UIDevice workaround
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

/**
 * The boundary used used for multi-part headers
 */
NSString* const kRKStringBoundary = @"0xKhTmLbOuNdArY";

@implementation RKParams

+ (RKParams*)params {
	RKParams* params = [[[RKParams alloc] init] autorelease];
	return params;
}

+ (RKParams*)paramsWithDictionary:(NSDictionary*)dictionary {
	RKParams* params = [[[RKParams alloc] initWithDictionary:dictionary] autorelease];
	return params;
}

- (id)init {
    self = [super init];
	if (self) {
		_attachments = [NSMutableArray new];
		_footer       = [[[NSString stringWithFormat:@"--%@--\r\n", kRKStringBoundary] dataUsingEncoding:NSUTF8StringEncoding] retain];
		_footerLength = [_footer length];
	}
	
	return self;
}

- (void)dealloc {
	[_attachments release];
    [_footer release];
    
	[super dealloc];
}

- (RKParams *)initWithDictionary:(NSDictionary *)dictionary {
    self = [self init];
	if (self) {
        // NOTE: We sort the keys to try and ensure given identical dictionaries we'll wind up
        // with matching MD5 checksums.
        NSArray *sortedKeys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		for (NSString *key in sortedKeys) {
			id value = [dictionary objectForKey:key];
			[self setValue:value forParam:key];
		}
	}
	
	return self;
}

- (RKParamsAttachment *)setValue:(id <NSObject>)value forParam:(NSString *)param {
	RKParamsAttachment *attachment = [[RKParamsAttachment alloc] initWithName:param value:value];
	[_attachments addObject:attachment];
	[attachment release];
	
	return attachment;
}

- (NSDictionary *)dictionaryOfPlainTextParams {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (RKParamsAttachment *attachment in _attachments)
        if (attachment.value)   // if the value exist, it is plain text param
            [result setValue:attachment.value forKey:attachment.name];
    return [NSDictionary dictionaryWithDictionary:result];
}

- (RKParamsAttachment *)setFile:(NSString *)filePath forParam:(NSString *)param {
	RKParamsAttachment *attachment = [[RKParamsAttachment alloc] initWithName:param file:filePath];
	[_attachments addObject:attachment];
	[attachment release];
	
	return attachment;
}

- (RKParamsAttachment *)setData:(NSData *)data forParam:(NSString *)param {
	RKParamsAttachment *attachment = [[RKParamsAttachment alloc] initWithName:param data:data];
	[_attachments addObject:attachment];
	[attachment release];
	
	return attachment;
}

- (RKParamsAttachment *)setData:(NSData *)data MIMEType:(NSString *)MIMEType forParam:(NSString *)param {
	RKParamsAttachment *attachment = [self setData:data forParam:param];
	if (MIMEType != nil) {
		attachment.MIMEType = MIMEType;
	}
	
	return attachment;
}

- (RKParamsAttachment *)setData:(NSData *)data MIMEType:(NSString *)MIMEType fileName:(NSString *)fileName forParam:(NSString *)param {
	RKParamsAttachment *attachment = [self setData:data forParam:param];
	if (MIMEType != nil) {
		attachment.MIMEType = MIMEType;
	}
	if (fileName != nil) {
		attachment.fileName = fileName;
	}
	
	return attachment;
}

- (RKParamsAttachment *)setFile:(NSString *)filePath MIMEType:(NSString *)MIMEType fileName:(NSString *)fileName forParam:(NSString *)param {
	RKParamsAttachment *attachment = [self setFile:filePath forParam:param];
	if (MIMEType != nil) {
		attachment.MIMEType = MIMEType;
	}
	if (fileName != nil) {
		attachment.fileName = fileName;
	}
	
	return attachment;
}

#pragma mark RKRequestSerializable methods

- (NSString *)HTTPHeaderValueForContentType {
	return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kRKStringBoundary];
}

- (NSUInteger)HTTPHeaderValueForContentLength {
	return _length;
}

- (void)reset {
    _bytesDelivered = 0;
    _length = 0;
    _streamStatus = NSStreamStatusNotOpen;
}

- (NSInputStream*)HTTPBodyStream {
	// Open each of our attachments
	[_attachments makeObjectsPerformSelector:@selector(open)];
	
	// Calculate the length	of the stream
    _length = _footerLength;	
	for (RKParamsAttachment *attachment in _attachments) {
		_length += [attachment length];
	}
	
	return (NSInputStream*)self;
}

#pragma mark NSInputStream methods

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)maxLength {
    NSUInteger bytesSentInThisRead = 0, bytesRead;
	NSUInteger lengthOfAttachments = (_length - _footerLength);
	
	// Proxy the read through to our attachments
    _streamStatus = NSStreamStatusReading;
    while (_bytesDelivered < _length && bytesSentInThisRead < maxLength && _currentPart < [_attachments count]) {
        if ((bytesRead = [[_attachments objectAtIndex:_currentPart] read:buffer + bytesSentInThisRead maxLength:maxLength - bytesSentInThisRead]) == 0) {
            _currentPart ++;
            continue;
        }
		
        bytesSentInThisRead += bytesRead;
        _bytesDelivered += bytesRead;
    }
	
	// If we have sent all the attachments data, begin emitting the boundary footer
    if ((_bytesDelivered >= lengthOfAttachments) && (bytesSentInThisRead < maxLength)) {
		NSUInteger footerBytesSent, footerBytesRemaining, bytesRemainingInBuffer;
		
		// Calculate our position in the stream & buffer
		footerBytesSent = _bytesDelivered - lengthOfAttachments;
		footerBytesRemaining = _footerLength - footerBytesSent;
		bytesRemainingInBuffer = maxLength - bytesSentInThisRead;
		
		// Send the entire footer back if there is room
        bytesRead = (footerBytesRemaining < bytesRemainingInBuffer) ? footerBytesRemaining : bytesRemainingInBuffer;		
        [_footer getBytes:buffer + bytesSentInThisRead range:NSMakeRange(footerBytesSent, bytesRead)];
		
        bytesSentInThisRead += bytesRead;
        _bytesDelivered += bytesRead;
    }
	
    return bytesSentInThisRead;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
	return NO;
}

- (BOOL)hasBytesAvailable {
    return _bytesDelivered < _length;
}

- (void)open {
    _streamStatus = NSStreamStatusOpen;
    RKLogTrace(@"RKParams stream opened...");
}

- (void)close {
    if (_streamStatus != NSStreamStatusClosed) {
        _streamStatus = NSStreamStatusClosed;
        
        RKLogTrace(@"RKParams stream closed. Releasing self.");        
        
#if TARGET_OS_IPHONE
        // NOTE: When we are assigned to the URL request, we get
        // retained. We release ourselves here to ensure the retain
        // count will hit zero after upload is complete.
        //
        // This behavior does not seem to happen on iOS 5. This is a workaround until
        // the problem can be analyzed in more detail
        if ([[[UIDevice currentDevice] systemVersion] compare:@"5.0" options:NSNumericSearch] == NSOrderedAscending) {
            [self release];
        }
#endif
    }
}

- (NSStreamStatus)streamStatus {
    if (_streamStatus != NSStreamStatusClosed && _bytesDelivered >= _length) {
        _streamStatus = NSStreamStatusAtEnd;
    }
	
    return _streamStatus;
}

- (NSArray *)attachments {
    return [NSArray arrayWithArray:_attachments];
}

- (NSString *)MD5 {
    NSMutableString *attachmentsMD5 = [[NSMutableString new] autorelease];
    for (RKParamsAttachment *attachment in self.attachments) {
        [attachmentsMD5 appendString:[attachment MD5]];
    }
    
    return [attachmentsMD5 MD5];
}

#pragma mark Core Foundation stream methods

- (void)_scheduleInCFRunLoop:(NSRunLoop *)runLoop forMode:(id)mode {
}

- (void)_setCFClientFlags:(CFOptionFlags)flags callback:(CFReadStreamClientCallBack)callback context:(CFStreamClientContext)context {
}

@end
