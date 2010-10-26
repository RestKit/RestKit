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
	if (self = [self init]) {
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

- (NSString*)ContentTypeHTTPHeader {
	return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kRKStringBoundary];
}

- (NSUInteger)HTTPHeaderValueForContentLength {
	NSLog(@"HTTPHeaderValueForContentLength called. Returned: %d", _length);
	return _length;
}

- (NSInputStream*)HTTPBodyStream {
	// Open each of our attachments
	[_attachments makeObjectsPerformSelector:@selector(open)];
	
	// Calculate the length	of the stream
    _length     = _footerLength;	
	for (RKParamsAttachment* attachment in _attachments) {
		_length += [attachment length];
	}
	
	return (NSInputStream*)self;
}

#pragma mark NSInputStream methods

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    NSUInteger sent = 0, read;
	NSUInteger lengthOfAttachments = (_length - _footerLength); // TODO: Make this a method???
	
	// Proxy the read through to our attachments
    _streamStatus = NSStreamStatusReading;
    while (_bytesDelivered < _length && sent < len && _currentPart < [_attachments count]) {
        if ((read = [[_attachments objectAtIndex:_currentPart] read:buffer + sent maxLength:len - sent]) == 0) {
            _currentPart ++;
            continue;
        }
		
        sent += read;
        _bytesDelivered += read;
    }
	
	// Append the boundary to the end of the stream
    if (_bytesDelivered >= (_length - _footerLength) && sent < len) {
		NSUInteger a, b;		
		a = _footerLength - (_bytesDelivered - lengthOfAttachments);
		b = len - sent;		
        read       = (a < b) ? a : b;
		
        [_footer getBytes:buffer + sent range:NSMakeRange(_bytesDelivered - lengthOfAttachments, read)];
        sent      += read;
        _bytesDelivered += read;
    }
	
    return sent;
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
