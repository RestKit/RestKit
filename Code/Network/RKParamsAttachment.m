//
//  RKParamsAttachment.m
//  RestKit
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <MobileCoreServices/UTType.h>
#endif
#import "RKParamsAttachment.h"

/**
 * The multi-part boundary. See RKParams.m
 */
extern NSString* const kRKStringBoundary;

@interface RKParamsAttachment (Private)
- (NSString *)mimeTypeForExtension:(NSString *)extension;
@end

@implementation RKParamsAttachment

@synthesize fileName = _fileName, MIMEType = _MIMEType, name = _name;

- (id)initWithName:(NSString*)name {
	if ((self = [self init])) {
        self.name = name;
        self.fileName = @"";
	}
	
	return self;
}

- (id)initWithName:(NSString*)name value:(id<NSObject>)value {
	if ((self = [self initWithName:name])) {
		NSMutableData* body = [NSMutableData data];
		if ([value respondsToSelector:@selector(dataUsingEncoding:)]) {
			[body appendData:[(NSString*)value dataUsingEncoding:NSUTF8StringEncoding]];
		} else {
			[body appendData:[[NSString stringWithFormat:@"%@", value] dataUsingEncoding:NSUTF8StringEncoding]];
		}
		
		_bodyStream    = [[NSInputStream inputStreamWithData:body] retain];
		_bodyLength    = [body length];
	}
	
	return self;
}

- (id)initWithName:(NSString*)name data:(NSData*)data {
	if ((self = [self initWithName:name])) {		
		_bodyStream    = [[NSInputStream inputStreamWithData:data] retain];
		_bodyLength    = [data length];
	}
	
	return self;
}

- (id)initWithName:(NSString*)name file:(NSString*)filePath {
	if ((self = [self initWithName:name])) {
		NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:filePath], @"Expected file to exist at path: %@", filePath);
		_fileName = [[filePath lastPathComponent] retain];
		_MIMEType = [[self mimeTypeForExtension:[filePath pathExtension]] retain];
		_bodyStream    = [[NSInputStream inputStreamWithFileAtPath:filePath] retain];
		
		NSError* error;
		NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
		if (attributes) {
			_bodyLength    = [[attributes objectForKey:NSFileSize] unsignedIntegerValue];
		}
		else {
			NSLog(@"Encountered an error while determining file size: %@", error);
		}
	}
	
	return self;
}

- (void)dealloc {
	[_fileName release];
	[_MIMEType release];
	
	[_MIMEHeader release];
	_MIMEHeader = nil;
	
    [_bodyStream close];
	[_bodyStream release];
	_bodyStream = nil;
	
    [super dealloc];
}

- (NSString*)MIMEBoundary {
	return kRKStringBoundary;
}

- (NSString *)mimeTypeForExtension:(NSString *)extension {
	if (NULL != UTTypeCreatePreferredIdentifierForTag) {
		CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)extension, NULL);
		if (uti != NULL) {
			CFStringRef mime = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
			CFRelease(uti);
			if (mime != NULL) {
				NSString *type = [NSString stringWithString:(NSString *)mime];
				CFRelease(mime);
				return type;
			}
		}
	}
	
    return @"application/octet-stream";
}

#pragma mark NSStream methods

- (void)open {
	// Generate the MIME header for this part
	if (self.fileName && self.MIMEType) {
		// Typical for file attachments
		_MIMEHeader = [[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"; "
												   @"filename=\"%@\"\r\nContent-Type: %@\r\n\r\n", 
						 [self MIMEBoundary], self.name, self.fileName, self.MIMEType] dataUsingEncoding:NSUTF8StringEncoding] retain];
	} else if (self.MIMEType) {
		// Typical for data values
		_MIMEHeader = [[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n"
												   @"Content-Type: %@\r\n\r\n", 
						 [self MIMEBoundary], self.name, self.MIMEType] dataUsingEncoding:NSUTF8StringEncoding] retain];
	} else {
		// Typical for raw values
		_MIMEHeader = [[[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n", 
						 [self MIMEBoundary], self.name] 
						dataUsingEncoding:NSUTF8StringEncoding] retain];
	}
	
	// Calculate lengths
	_MIMEHeaderLength = [_MIMEHeader length];
	_length = _MIMEHeaderLength + _bodyLength + 2; // \r\n is the + 2
	
	// Open the stream
    [_bodyStream open];
}

- (NSUInteger)length {
    return _length;
}

- (NSUInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)maxLength {
    NSUInteger sent = 0, read;
	
	// We are done with the read
    if (_delivered >= _length) {
        return 0;
    }
	
	// First we send back the MIME headers
    if (_delivered < _MIMEHeaderLength && sent < maxLength) {
		NSUInteger headerBytesRemaining, bytesRemainingInBuffer;
		
		headerBytesRemaining = _MIMEHeaderLength - _delivered;
		bytesRemainingInBuffer = maxLength - sent;
		
		// Send the entire header if there is room
        read       = (headerBytesRemaining < bytesRemainingInBuffer) ? headerBytesRemaining : bytesRemainingInBuffer;
        [_MIMEHeader getBytes:buffer + sent range:NSMakeRange(_delivered, read)];
		
        sent += read;
        _delivered += sent;
    }
	
	// Read the attachment body out of our underlying stream
    while (_delivered >= _MIMEHeaderLength && _delivered < (_length - 2) && sent < maxLength) {
        if ((read = [_bodyStream read:(buffer + sent) maxLength:(maxLength - sent)]) == 0) {
            break;
        }
		
        sent += read;
        _delivered += read;
    }
	
	// Append the \r\n 
    if (_delivered >= (_length - 2) && sent < maxLength) {
        if (_delivered == (_length - 2)) {
            *(buffer + sent) = '\r';
            sent ++;
			_delivered ++;
        }
		
        *(buffer + sent) = '\n';
        sent ++;
		_delivered ++;
    }
	
    return sent;
}

@end
