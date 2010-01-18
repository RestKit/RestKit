//
//  OTRestParams.m
//  OTRestFramework
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "OTRestParams.h"

static NSString* kOTRestStringBoundary = @"0xKhTmLbOuNdArY";

@implementation OTRestParams

+ (OTRestParams*)params {
	OTRestParams* params = [[[OTRestParams alloc] init] autorelease];
	return params;
}

+ (OTRestParams*)paramsWithDictionary:(NSDictionary*)dictionary {
	OTRestParams* params = [[[OTRestParams alloc] initWithDictionary:dictionary] autorelease];
	return params;
}

- (id)init {
	if (self = [super init]) {
		_valueData = [[NSMutableDictionary alloc] init];
		_fileData = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[_valueData release];
	[_fileData release];
	[super dealloc];
}

- (OTRestParams*)initWithDictionary:(NSDictionary*)dictionary {
	if (self = [super init]) {
		_valueData = [[NSMutableDictionary dictionaryWithDictionary:dictionary] retain];
		_fileData = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)setValue:(id <NSObject>)value forParam:(NSString*)param {
	[_valueData setObject:value forKey:param];
}

- (OTRestParamsFileAttachment*)setFile:(NSString*)filePath forParam:(NSString*)param {
	OTRestParamsFileAttachment* attachment = [OTRestParamsFileAttachment attachment];
	attachment.filePath = filePath;
	[_fileData setObject:attachment forKey:param];
	return attachment;
}

- (OTRestParamsFileAttachment*)setFile:(NSString*)filePath MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param {
	OTRestParamsFileAttachment* attachment = [self setFile:filePath forParam:param];
	if (MIMEType != nil) {
		attachment.MIMEType = MIMEType;
	}
	if (fileName != nil) {
		attachment.fileName = fileName;
	}
	return attachment;
}

- (OTRestParamsDataAttachment*)setData:(NSData*)data forParam:(NSString*)param {
	OTRestParamsDataAttachment* attachment = [OTRestParamsDataAttachment attachment];
	attachment.data = data;
	[_fileData setObject:attachment forKey:param];
	return attachment;
}

- (OTRestParamsDataAttachment*)setData:(NSData*)data MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param {
	OTRestParamsDataAttachment* attachment = [self setData:data forParam:param];
	if (MIMEType != nil) {
		attachment.MIMEType = MIMEType;
	}
	if (fileName != nil) {
		attachment.fileName = fileName;
	}
	return attachment;
}

- (NSData*)endItemBoundary {
	return [[NSString stringWithFormat:@"\r\n--%@\r\n", kOTRestStringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)addValuesToHTTPBody:(NSMutableData*)HTTPBody {
	int i = 0;
	for (id key in _valueData) {
		id value = [_valueData valueForKey:key];
		NSLog(@"Attempting to add HTTP param named %@ with type %@ and value %@", key, [value class], value);
		[HTTPBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
		// TODO: Can get _PFCachedNumber objects back from valueForKey: from Core Data. Need to figure this out...
		if ([value respondsToSelector:@selector(dataUsingEncoding:)]) {
			[HTTPBody appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
		} else {
			[HTTPBody appendData:[[NSString stringWithFormat:@"%@", value] dataUsingEncoding:NSUTF8StringEncoding]];
		}		
		i++;
		
		// Only add the boundary if this is not the last item in the post body
		if (i != [_valueData count] || [_fileData count] > 0) {
			[HTTPBody appendData:[self endItemBoundary]];
		}
	}
}

- (void)addAttachmentsToHTTPBody:(NSMutableData*)HTTPBody {	
	int i = 0;
	for (id key in _fileData) {
		OTRestParamsAttachment* attachment = (OTRestParamsAttachment*) [_fileData valueForKey:key];
		[HTTPBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, attachment.fileName] dataUsingEncoding:NSUTF8StringEncoding]];
		[HTTPBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", attachment.MIMEType] dataUsingEncoding:NSUTF8StringEncoding]];
		[attachment writeAttachmentToHTTPBody:HTTPBody];
		i++;
		
		if (i != [_fileData count]) {
			[HTTPBody appendData:[self endItemBoundary]];
		}
	}
}

- (NSData*)HTTPBody {
	NSMutableData* HTTPBody = [NSMutableData data];
	
	[HTTPBody appendData:[[NSString stringWithFormat:@"--%@\r\n", kOTRestStringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[self addValuesToHTTPBody:HTTPBody];
	[self addAttachmentsToHTTPBody:HTTPBody];
	[HTTPBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", kOTRestStringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	return HTTPBody;
}

- (NSString*)ContentTypeHTTPHeader {
	return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kOTRestStringBoundary];
}

@end
