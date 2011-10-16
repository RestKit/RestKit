//
//  RKParamsAttachment.m
//  RestKit
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Two Toasters
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

#import "RKParamsAttachment.h"
#import "RKLog.h"
#import "NSData+MD5.h"
#import "FileMD5Hash.h"
#import "../Support/NSString+RestKit.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

/**
 * The multi-part boundary. See RKParams.m
 */
extern NSString* const kRKStringBoundary;

@implementation RKParamsAttachment

@synthesize filePath = _filePath;
@synthesize fileName = _fileName;
@synthesize MIMEType = _MIMEType;
@synthesize name = _name;

- (id)initWithName:(NSString *)name {
    self = [self init];
	if (self) {
        self.name = name;
        self.fileName = name;
	}
	
	return self;
}

- (id)initWithName:(NSString *)name value:(id<NSObject>)value {
	if ((self = [self initWithName:name])) {
		if ([value respondsToSelector:@selector(dataUsingEncoding:)]) {
            _body = [[(NSString*)value dataUsingEncoding:NSUTF8StringEncoding] retain];
		} else {
			_body = [[[NSString stringWithFormat:@"%@", value] dataUsingEncoding:NSUTF8StringEncoding] retain];
		}        
        
		_bodyStream    = [[NSInputStream alloc] initWithData:_body];
		_bodyLength    = [_body length];
	}
	
	return self;
}

- (id)initWithName:(NSString*)name data:(NSData*)data {
    self = [self initWithName:name];
	if (self) {
        _body          = [data retain];
		_bodyStream    = [[NSInputStream alloc] initWithData:data];
		_bodyLength    = [data length];
	}
	
	return self;
}

- (id)initWithName:(NSString*)name file:(NSString*)filePath {
    self = [self initWithName:name];
	if (self) {
		NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:filePath], @"Expected file to exist at path: %@", filePath);
        _filePath = [filePath retain];
        _fileName = [[filePath lastPathComponent] retain];
        NSString *MIMEType = [filePath MIMETypeForPathExtension];
        if (! MIMEType) MIMEType = @"application/octet-stream";        
		_MIMEType = [MIMEType retain];
		_bodyStream = [[NSInputStream alloc] initWithFileAtPath:filePath];
		
		NSError* error;
		NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
		if (attributes) {
			_bodyLength    = [[attributes objectForKey:NSFileSize] unsignedIntegerValue];
		}
		else {
			RKLogError(@"Encountered an error while determining file size: %@", error);
		}
	}
	
	return self;
}

- (void)dealloc {
    [_name release];    
    [_body release];
    [_filePath release];
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
		bytesRemainingInBuffer = maxLength;
		
		// Send the entire header if there is room
        read       = (headerBytesRemaining < bytesRemainingInBuffer) ? headerBytesRemaining : bytesRemainingInBuffer;
        [_MIMEHeader getBytes:buffer range:NSMakeRange(_delivered, read)];
		
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

// NOTE: Cannot handle MD5 for files. We don't want to read the contents into memory
- (NSString *)MD5 {
    if (_body) {
        return [_body MD5];
    } else if (_filePath) {
        CFStringRef fileAttachmentMD5 = FileMD5HashCreateWithPath((CFStringRef)_filePath, 
                                                                  FileHashDefaultChunkSizeForReadingData);
        return [(NSString *)fileAttachmentMD5 autorelease];
    } else {
        RKLogWarning(@"Failed to generate MD5 for attachment: unknown data type.");
        return nil;
    }
}

@end
