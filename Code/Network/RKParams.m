//
//  RKParams.m
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKParams.h"

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
	if (self = [super init]) {
		_attachments = [NSMutableArray new];
		_footer       = [[[NSString stringWithFormat:@"--%@--\r\n", kRKStringBoundary] dataUsingEncoding:NSUTF8StringEncoding] retain];
		_footerLength = [_footer length];
	}
	
	return self;
}

- (void)dealloc {
	[_attachments release];
	[super dealloc];
}

- (RKParams*)initWithDictionary:(NSDictionary*)dictionary {
	if ((self = [self init])) {
		for (NSString* key in dictionary) {
			id value = [dictionary objectForKey:key];
			[self setValue:value forParam:key];
		}
	}
	
	return self;
}

- (RKParamsAttachment*)setValue:(id <NSObject>)value forParam:(NSString*)param {
	RKParamsAttachment* attachment = [[RKParamsAttachment alloc] initWithName:param value:value];
	[_attachments addObject:attachment];
	[attachment release];
	
	return attachment;
}

- (RKParamsAttachment*)setFile:(NSString*)filePath forParam:(NSString*)param {
	RKParamsAttachment* attachment = [[RKParamsAttachment alloc] initWithName:param file:filePath];
	[_attachments addObject:attachment];
	[attachment release];
	
	return attachment;
}

- (RKParamsAttachment*)setData:(NSData*)data forParam:(NSString*)param {
	RKParamsAttachment* attachment = [[RKParamsAttachment alloc] initWithName:param data:data];
	[_attachments addObject:attachment];
	[attachment release];
	
	return attachment;
}

- (RKParamsAttachment*)setData:(NSData*)data MIMEType:(NSString*)MIMEType forParam:(NSString*)param {
	RKParamsAttachment* attachment = [self setData:data forParam:param];
	if (MIMEType != nil) {
		attachment.MIMEType = MIMEType;
	}
	
	return attachment;
}

- (RKParamsAttachment*)setData:(NSData*)data MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param {
	RKParamsAttachment* attachment = [self setData:data forParam:param];
	if (MIMEType != nil) {
		attachment.MIMEType = MIMEType;
	}
	if (fileName != nil) {
		attachment.fileName = fileName;
	}
	
	return attachment;
}

- (RKParamsAttachment*)setFile:(NSString*)filePath MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param {
	RKParamsAttachment* attachment = [self setFile:filePath forParam:param];
	if (MIMEType != nil) {
		attachment.MIMEType = MIMEType;
	}
	if (fileName != nil) {
		attachment.fileName = fileName;
	}
	
	return attachment;
}

#pragma mark RKRequestSerializable methods

- (NSString*)HTTPHeaderValueForContentType {
	return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kRKStringBoundary];
}

- (NSUInteger)HTTPHeaderValueForContentLength {
	return _length;
}

- (NSInputStream*)HTTPBodyStream {
	// Open each of our attachments
	[_attachments makeObjectsPerformSelector:@selector(open)];
	
	// Calculate the length	of the stream
    _length = _footerLength;	
	for (RKParamsAttachment* attachment in _attachments) {
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
}

- (void)close {
    _streamStatus = NSStreamStatusClosed;
}

- (NSStreamStatus)streamStatus {
    if (_streamStatus != NSStreamStatusClosed && _bytesDelivered >= _length) {
        _streamStatus = NSStreamStatusAtEnd;
    }
	
    return _streamStatus;
}

#pragma mark Core Foundation stream methods

- (void)_scheduleInCFRunLoop:(NSRunLoop *)runLoop forMode:(id)mode {
}

- (void)_setCFClientFlags:(CFOptionFlags)flags callback:(CFReadStreamClientCallBack)callback context:(CFStreamClientContext)context {
}

@end
