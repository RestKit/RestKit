//
//  RKParams.m
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKParams.h"

static NSString* kRKStringBoundary = @"0xKhTmLbOuNdArY";

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

- (RKParams*)initWithDictionary:(NSDictionary*)dictionary {
	if (self = [super init]) {
		_valueData = [[NSMutableDictionary dictionaryWithDictionary:dictionary] retain];
		_fileData = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)setValue:(id <NSObject>)value forParam:(NSString*)param {
	[_valueData setObject:value forKey:param];
}

- (RKParamsFileAttachment*)setFile:(NSString*)filePath forParam:(NSString*)param {
	RKParamsFileAttachment* attachment = [RKParamsFileAttachment attachment];
	attachment.filePath = filePath;
	[_fileData setObject:attachment forKey:param];
	return attachment;
}

- (RKParamsFileAttachment*)setFile:(NSString*)filePath MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param {
	RKParamsFileAttachment* attachment = [self setFile:filePath forParam:param];
	if (MIMEType != nil) {
		attachment.MIMEType = MIMEType;
	}
	if (fileName != nil) {
		attachment.fileName = fileName;
	}
	return attachment;
}

- (RKParamsDataAttachment*)setData:(NSData*)data forParam:(NSString*)param {
	RKParamsDataAttachment* attachment = [RKParamsDataAttachment attachment];
	attachment.data = data;
	[_fileData setObject:attachment forKey:param];
	return attachment;
}

- (RKParamsDataAttachment*)setData:(NSData*)data MIMEType:(NSString*)MIMEType fileName:(NSString*)fileName forParam:(NSString*)param {
	RKParamsDataAttachment* attachment = [self setData:data forParam:param];
	if (MIMEType != nil) {
		attachment.MIMEType = MIMEType;
	}
	if (fileName != nil) {
		attachment.fileName = fileName;
	}
	return attachment;
}

- (NSData*)endItemBoundary {
	return [[NSString stringWithFormat:@"\r\n--%@\r\n", kRKStringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)addValuesToHTTPBody:(NSMutableData*)HTTPBody {
	int i = 0;
	for (id key in _valueData) {
		id value = [_valueData valueForKey:key];
		if ([value isKindOfClass:[NSArray class]]) {
			int j = 0;
			for (id object in (NSArray*)value) {
				NSString* arrayKey = [NSString stringWithFormat:@"%@[]", key];
				NSLog(@"Attempting to add HTTP param named %@ with type %@ and value %@", arrayKey, [object class], object);
				[HTTPBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", arrayKey] dataUsingEncoding:NSUTF8StringEncoding]];
				// TODO: Can get _PFCachedNumber objects back from valueForKey: from Core Data. Need to figure this out...
				if ([object respondsToSelector:@selector(dataUsingEncoding:)]) {
					[HTTPBody appendData:[object dataUsingEncoding:NSUTF8StringEncoding]];
				} else {
					[HTTPBody appendData:[[NSString stringWithFormat:@"%@", object] dataUsingEncoding:NSUTF8StringEncoding]];
				}
				j++;
				if (j != [value count]) {
					[HTTPBody appendData:[self endItemBoundary]];
				}
			}
		} else {
			NSLog(@"Attempting to add HTTP param named %@ with type %@ and value %@", key, [value class], value);
			[HTTPBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
			// TODO: Can get _PFCachedNumber objects back from valueForKey: from Core Data. Need to figure this out...
			if ([value respondsToSelector:@selector(dataUsingEncoding:)]) {
				[HTTPBody appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
			} else {
				[HTTPBody appendData:[[NSString stringWithFormat:@"%@", value] dataUsingEncoding:NSUTF8StringEncoding]];
			}
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
		RKParamsAttachment* attachment = (RKParamsAttachment*) [_fileData valueForKey:key];
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
	
	[HTTPBody appendData:[[NSString stringWithFormat:@"--%@\r\n", kRKStringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[self addValuesToHTTPBody:HTTPBody];
	[self addAttachmentsToHTTPBody:HTTPBody];
	[HTTPBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", kRKStringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	return HTTPBody;
}

- (NSString*)ContentTypeHTTPHeader {
	return [NSString stringWithFormat:@"multipart/form-data; boundary=%@", kRKStringBoundary];
}

@end
