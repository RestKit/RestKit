//
//  RKParams.m
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKParams.h"
#import "../Support/RKLog.h"
#import <objc/runtime.h>

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

@interface RKParams (NSInputStreamInternals)

-(void)_scheduleRunLoopSource:(CFRunLoopRef)rl forMode:(NSString *)mode;
-(void)_cancelRunLoopSource:(CFRunLoopRef)rl forMode:(NSString *)mode;
-(void)_perfom;
-(void)_queueEvents:(NSStreamEvent) eventCode second:(NSStreamEvent) secondCode;
-(void)_queueEvent:(NSStreamEvent) eventCode;

- (void)scheduleInCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)mode;
- (void)unscheduleFromCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)mode;

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
	return [[[RKParams alloc] init] autorelease];
}

+ (RKParams*)paramsWithDictionary:(NSDictionary*)dictionary {
	return [[[RKParams alloc] initWithDictionary:dictionary] autorelease];
}

- (id)init {
    self = [super init];
	if (self) {
		_attachments = [NSMutableArray new];
		_attachmentStreams = [NSMutableArray new];
        _eventQueue = [[NSMutableArray alloc] init];
        
		_runLoopSource = nil;
		_constructed = NO;
	}
	
	return self;
}

- (void)dealloc {
    [self close];
    
    NSLog(@"DEALLOCING");
	[_attachments release];
	[_attachmentStreams release];
    [_eventQueue release];
	
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
	RKParamsAttachment* attachment = nil;
	
	if ([value isKindOfClass:[NSDictionary class]]) {
		NSDictionary *dict = (NSDictionary *)value;
		for (id key in dict) {
			attachment = [self setValue:[dict objectForKey:key] 
							   forParam:[NSString stringWithFormat:@"%@[%@]", param, key]];
		}
	} else {
		attachment = [[RKParamsAttachment alloc] initWithName:param value:value];
		[_attachments addObject:attachment];
		[attachment release];
	}
	
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

- (NSStreamStatus)streamStatus {
    return _streamStatus;
}

- (void)open {
    @synchronized (self) {
        _currentAttachmentStream = nil;
        _streamStatus = NSStreamStatusOpening;
        NSLog(@"OPENING");
        
        if ([_attachmentStreams count] > 0) {
            [_attachmentStreams makeObjectsPerformSelector:@selector(open)];
            _currentAttachmentIndex = 0;
            _currentAttachmentStream = [_attachmentStreams objectAtIndex:_currentAttachmentIndex];
        }
        
        _streamStatus = NSStreamStatusOpen;
        RKLogTrace(@"RKParams stream opened...");
    }
}

- (void)close {
    @synchronized (self) {
        if (_streamStatus != NSStreamStatusClosed) {
            _streamStatus = NSStreamStatusClosed;
            
            NSLog(@"CLOSING");
            RKLogTrace(@"RKParams stream closed. Releasing self.");      
            
            [_attachmentStreams makeObjectsPerformSelector:@selector(close)];
            
            CFRunLoopSourceInvalidate(_runLoopSource);
            CFRelease(_runLoopSource); _runLoopSource = nil;
            
            // NOTE: When we are assigned to the URL request, we get
            // retained. We release ourselves here to ensure the retain
            // count will hit zero after upload is complete.
            //[self release];
        }
    }
}


- (BOOL)hasBytesAvailable {
    return [_currentAttachmentStream hasBytesAvailable];
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)maxLen {
    if (_currentAttachmentStream == nil) {
        return 0;
	}
    
    NSInteger result = 0;
    
    do {
        NSInteger incrementalRead = [_currentAttachmentStream read:&buffer[result] maxLength:(maxLen - result)];
        
        if (incrementalRead == 0) {
            _currentAttachmentIndex++;
            if (_currentAttachmentIndex < [_attachmentStreams count]) {
                _currentAttachmentStream = [_attachmentStreams objectAtIndex:_currentAttachmentIndex];
            } else {
                _currentAttachmentStream = nil;
            }
        } else {
            result += incrementalRead;
        }
    } while (_currentAttachmentStream && result < maxLen);
    
    if (_currentAttachmentStream) {
        _streamStatus = NSStreamStatusReading;
        [self _queueEvent:NSStreamEventHasBytesAvailable];
    } else {
        _streamStatus = NSStreamStatusAtEnd;
        [self _queueEvent:NSStreamEventEndEncountered];
    }
    
    NSLog(@"Read %d bytes but wanted %d!", result, maxLen);
	
    return result;
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len {
    return NO;
}

- (void)scheduleInRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    NSLog(@"SCHEDULING");
    [self scheduleInCFRunLoop:[aRunLoop getCFRunLoop] forMode:(CFStringRef) mode];
}

- (void)removeFromRunLoop:(NSRunLoop *)aRunLoop forMode:(NSString *)mode {
    NSLog(@"REMOVING");
    [self unscheduleFromCFRunLoop:[aRunLoop getCFRunLoop] forMode:(CFStringRef) mode];
}

#pragma mark Core Foundation stream methods

+ (BOOL)resolveInstanceMethod:(SEL) selector {
    NSString * name = NSStringFromSelector(selector);
    
    if ([name hasPrefix:@"_"]) {
        name = [name substringFromIndex:1];
        SEL aSelector = NSSelectorFromString(name);
        Method method = class_getInstanceMethod(self, aSelector);
        
        if (method) {
            class_addMethod(self,
                            selector,
                            method_getImplementation(method),
                            method_getTypeEncoding(method));
            return YES;
        }
    }
    
    return [super resolveInstanceMethod:selector];
}

- (BOOL)setCFClientFlags:(CFOptionFlags)inFlags
                callback:(CFReadStreamClientCallBack)inCallback
                context:(CFStreamClientContext *)inContext {
	
	if (inCallback != NULL) {
        NSLog(@"Setting flags!");
		_clientFlags = inFlags;
		_clientCallback = inCallback;
        
		memcpy(&_clientContext, inContext, sizeof(CFStreamClientContext));
		if (_clientContext.info && _clientContext.retain) {
			_clientContext.retain(_clientContext.info);
		}
	} else {
        NSLog(@"Clearing flags!");
		_clientFlags = kCFStreamEventNone;
		_clientCallback = NULL;
        
		if (_clientContext.info && _clientContext.release) {
			_clientContext.release(_clientContext.info);
		}
		
		memset(&_clientContext, 0, sizeof(CFStreamClientContext));
	}
	
	return YES;	
}

- (void)scheduleInCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)runLoopMode {
	@synchronized (self) {	
		if (!_runLoopSource) {
            NSLog(@"SCHEDULED IN RUN LOOP");
            
			CFRunLoopSourceContext context;
			context.version = 0;
			context.info = self;
			context.retain = NULL;
			context.release = NULL;
			context.copyDescription = NULL;
			context.equal = NULL;
			context.hash = NULL;
			context.schedule = RKParamsStreamRunLoopSourceScheduleRoutine;
			context.cancel = RKParamsStreamRunLoopSourceCancelRoutine;
			context.perform = RKParamsStreamRunLoopSourcePerformRoutine;
			
			_runLoopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &context);
			
			_scheduledRunLoop = runLoop;
			CFRunLoopAddSource(runLoop, _runLoopSource, (CFStringRef)runLoopMode);			
		}
	}
}

- (void)unscheduleFromCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)runLoopMode {
	@synchronized (self) {
        NSLog(@"UNSCHEDULED IN RUN LOOP");
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
        NSLog(@"PERFROMING EVENT");
		for (NSInteger index = 0; index < [_eventQueue count]; index++) {
			NSStreamEvent eventCode = [[_eventQueue objectAtIndex:0] unsignedIntegerValue];
			
			// coalescing identical events
			while ([_eventQueue count] > 0 && eventCode == [[_eventQueue objectAtIndex:0] unsignedIntegerValue] ) {
				[_eventQueue removeObjectAtIndex:0];
			}
			
			if ((eventCode & _clientFlags) == eventCode) {
				(*_clientCallback)((CFReadStreamRef)self, eventCode, _clientContext.info);
			}
		}
	}
}

-(void)_queueEvents:(NSStreamEvent) eventCode second:(NSStreamEvent) secondCode {
	@synchronized (self) {
        NSLog(@"ENQUEUEING TWO EVENTS");
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
        NSLog(@"ENQUEUEING EVENT");
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
