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
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork


@interface RKParamsAttachment (Private)

- (NSString *)mimeTypeForExtension:(NSString *)extension;

@end


@implementation RKParamsAttachment

@synthesize fileName = _fileName, MIMEType = _MIMEType, name = _name;
@synthesize bodyStream = _bodyStream, bodyLength = _bodyLength;

- (id)initWithName:(NSString*)name {
	if ((self = [self init])) {
        self.name = name;
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
		
		_bodyStream    = [[NSInputStream alloc] initWithData:body];
		_bodyLength    = [body length];
	}
	
	return self;
}

- (id)initWithName:(NSString*)name data:(NSData*)data {
	if ((self = [self initWithName:name])) {		
		_bodyStream    = [[NSInputStream alloc] initWithData:data];
		_bodyLength    = [data length];
	}
	
	return self;
}

- (id)initWithName:(NSString*)name file:(NSString*)filePath {
	if ((self = [self initWithName:name])) {
		NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:filePath], @"Expected file to exist at path: %@", filePath);
		_fileName = [[filePath lastPathComponent] retain];
		_MIMEType = [[self mimeTypeForExtension:[filePath pathExtension]] retain];
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

- (NSString *)MIMEHeader {
	if (_fileName) {
		return [[NSString alloc] initWithFormat:@"Content-Disposition: form-data; name=\"%@\"; "
								   @"filename=\"%@\"\r\nContent-Type: %@\r\n\r\n", 
									_name, _fileName, _MIMEType];
	}
	
	return [[NSString alloc] initWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",
											_name];
}

- (void)dealloc {
    [_name release];
    [_fileName release];
    [_MIMEType release];

    [_bodyStream close];
    [_bodyStream release];
    _bodyStream = nil;

    [super dealloc];
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

@end
