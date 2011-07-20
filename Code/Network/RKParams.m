//
//  RKParams.m
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKParams.h"
#import "../Support/RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

@interface RKParams (NSInputStreamInternals)

-(void)_scheduleRunLoopSource:(CFRunLoopRef)rl forMode:(NSString *)mode;
-(void)_cancelRunLoopSource:(CFRunLoopRef)rl forMode:(NSString *)mode;
-(void)_perfom;
-(void)_queueEvents:(NSStreamEvent) eventCode second:(NSStreamEvent) secondCode;
-(void)_queueEvent:(NSStreamEvent) eventCode;

@end

void RKParamsStreamRunLoopSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode);
void RKParamsStreamRunLoopSourcePerformRoutine (void *info);
void RKParamsStreamRunLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode);


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
		_attachmentStreams = [NSMutableArray new];
		
		_runLoopSource = nil;
		_constructed = NO;
	}
	
	return self;
}

- (void)dealloc {
	[_attachments release];
	[_attachmentStreams release];
	
	[super dealloc];
}

- (RKParams*)initWithDictionary:(NSDictionary*)dictionary {
    self = [self init];
	if (self) {
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
	return [NSString stringWithFormat:@"multipart/form-data;boundary=%@", kRKStringBoundary];
}

- (unsigned long long)HTTPHeaderValueForContentLength {
	return _length;
}

- (NSInputStream*)HTTPBodyStream {
	if (!_constructed) {
		NSString *firstDelimiter = [NSString stringWithFormat: @"--%@\r\n", kRKStringBoundary];
		NSString *middleDelimiter = [NSString stringWithFormat: @"\r\n--%@\r\n", kRKStringBoundary];
		NSString *delimiter = firstDelimiter;
		
		for (RKParamsAttachment *attachment in _attachments) {
			NSMutableString *headers = [NSMutableString stringWithString:delimiter];
			[headers appendString:[attachment MIMEHeader]];
			
			NSData *headersData = [headers dataUsingEncoding:NSUTF8StringEncoding];
			NSInputStream *headerStream = [NSInputStream inputStreamWithData:headersData];
			[_attachmentStreams addObject:headerStream];
			_length += [headersData length];
			
			[_attachmentStreams addObject:[attachment bodyStream]];
			_length += [attachment bodyLength];
			
			delimiter = middleDelimiter;
		}
		
		NSString *finalDelimiter = [NSString stringWithFormat: @"\r\n--%@--\r\n", kRKStringBoundary];
		NSData *finalDelimiterData = [finalDelimiter dataUsingEncoding:NSUTF8StringEncoding];
		NSInputStream *finalDelimiterStream = [NSInputStream inputStreamWithData:finalDelimiterData];
		[_attachmentStreams addObject:finalDelimiterStream];
		_length += [finalDelimiterData length];
	}
	
	return (NSInputStream*)self;
}

#pragma mark NSInputStream methods

- (void)open {
    _currentAttachmentStream = nil;
	_eventQueue = [[NSMutableArray alloc] init];
	
    if ([_attachmentStreams count] > 0) {
		[_attachmentStreams makeObjectsPerformSelector:@selector(open)];
		_currentAttachmentIndex = 0;
        _currentAttachmentStream = [_attachmentStreams objectAtIndex:_currentAttachmentIndex];
	}
	
	_streamStatus = NSStreamStatusOpen;
    RKLogTrace(@"RKParams stream opened...");
}

- (void)close {
    if (_streamStatus != NSStreamStatusClosed) {
        _streamStatus = NSStreamStatusClosed;
        
        RKLogTrace(@"RKParams stream closed. Releasing self.");   
		
		@synchronized (self) {
			[_eventQueue release]; _eventQueue = nil;
			[_attachmentStreams makeObjectsPerformSelector:@selector(close)];
			
			CFRunLoopSourceInvalidate(_runLoopSource);
			CFRelease(_runLoopSource); _runLoopSource = nil;   
		}
        
        // NOTE: When we are assigned to the URL request, we get
        // retained. We release ourselves here to ensure the retain
        // count will hit zero after upload is complete.
        [self release];
    }
}


- (BOOL)hasBytesAvailable {
    return _currentAttachmentStream != nil;
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len {
    if (_currentAttachmentStream == nil) {
        return 0;
	}
    
    NSInteger result = [_currentAttachmentStream read:buffer maxLength:len];
    if (result == 0 && (_currentAttachmentIndex < [_attachmentStreams count] - 1)) {
        _currentAttachmentIndex++;
        _currentAttachmentStream = [_attachmentStreams objectAtIndex:_currentAttachmentIndex];
        result = [self read:buffer maxLength:len];
    }
    
    if (result == 0) {
        _currentAttachmentStream = nil;
	}
	
	[self _queueEvent:NSStreamEventHasBytesAvailable];	
	
    return result;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
    return NO;
}

#pragma mark Core Foundation stream methods

- (BOOL)_setCFClientFlags:(CFOptionFlags)theStreamEvents 
				 callback:(CFReadStreamClientCallBack)clientCB 
				  context:(CFStreamClientContext*)clientContext {
	_clientCallback = clientCB;
	_streamEvents = theStreamEvents;
	
	if (clientContext) {
		_clientInfo = clientContext->info;
	} else {
		_clientInfo = nil;
	}
	
	return YES;
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
	// no-op
}

- (void)_scheduleInCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)runLoopMode {
	@synchronized (self) {		
		if (!_runLoopSource) {
			CFRunLoopSourceContext context;
			
			// Setup the context.
			context.version = 0;
			context.info = self;
			context.retain = NULL;
			context.release = NULL;
			context.copyDescription = CFCopyDescription;
			context.equal = CFEqual;
			context.hash = CFHash;
			context.schedule = RKParamsStreamRunLoopSourceScheduleRoutine;
			context.cancel = RKParamsStreamRunLoopSourceCancelRoutine;
			context.perform = RKParamsStreamRunLoopSourcePerformRoutine;
			
			_runLoopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
			
			_scheduledRunLoop = runLoop;
			CFRunLoopAddSource(runLoop, _runLoopSource, (CFStringRef)runLoopMode);			
		}
	}
}

- (void) _unscheduleFromCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)runLoopMode {
	@synchronized (self) {
		_scheduledRunLoop = nil;
		CFRunLoopRemoveSource(runLoop, _runLoopSource, (CFStringRef)runLoopMode);
	}
}

-(void)_scheduleRunLoopSource:(CFRunLoopRef)rl forMode:(NSString *)mode {
	// no-op
}

-(void)_cancelRunLoopSource:(CFRunLoopRef)rl forMode:(NSString *)mode {
	// no-op
}

-(void)_perfom {
	@synchronized (self) {
		for (NSInteger index = 0; index < [_eventQueue count]; index++) {
			NSStreamEvent eventCode = [[_eventQueue objectAtIndex:0] unsignedIntegerValue];
			
			// coalescing identical events
			while ([_eventQueue count] > 0 && eventCode == [[_eventQueue objectAtIndex:0] unsignedIntegerValue] ) {
				[_eventQueue removeObjectAtIndex:0];
			}
			
			if ( (eventCode & _streamEvents) == eventCode) {
				(*_clientCallback)((CFReadStreamRef)self, eventCode, _clientInfo);
			}
		}
	}
}

-(void)_queueEvents:(NSStreamEvent) eventCode second:(NSStreamEvent) secondCode {
	@synchronized (self) {
		if (!_scheduledRunLoop || !_eventQueue) {
			return;
		}
		
		[_eventQueue addObject:[NSNumber numberWithUnsignedInteger:eventCode]];
		[_eventQueue addObject:[NSNumber numberWithUnsignedInteger:secondCode]];

		CFRunLoopSourceSignal(_runLoopSource);
		if (CFRunLoopIsWaiting(_scheduledRunLoop)) {
			CFRunLoopWakeUp(_scheduledRunLoop); 
		}
	}
}


-(void)_queueEvent:(NSStreamEvent) eventCode {
	@synchronized (self) {
		if (!_scheduledRunLoop || !_eventQueue) {
			return;
		}
		
		[_eventQueue addObject:[NSNumber numberWithUnsignedInteger:eventCode]];
		
		// and signal & wakeup
		CFRunLoopSourceSignal(_runLoopSource);
		if (CFRunLoopIsWaiting(_scheduledRunLoop)) {
			CFRunLoopWakeUp(_scheduledRunLoop);
		}
	}
}

@end



void RKParamsStreamRunLoopSourceScheduleRoutine (void *info, CFRunLoopRef rl, CFStringRef mode) {
	[(RKParams*)info _scheduleRunLoopSource:rl forMode:(NSString*)mode];
}

void RKParamsStreamRunLoopSourcePerformRoutine (void *info) {
	[(RKParams*)info _perfom];
}

void RKParamsStreamRunLoopSourceCancelRoutine (void *info, CFRunLoopRef rl, CFStringRef mode) {
	[(RKParams*)info _cancelRunLoopSource:rl forMode:(NSString*)mode];
}
