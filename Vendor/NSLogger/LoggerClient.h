/*
 * LoggerClient.h
 *
 * version 1.0b10 2011-02-18
 *
 * Part of NSLogger (client side)
 * https://github.com/fpillet/NSLogger
 *
 * BSD license follows (http://www.opensource.org/licenses/bsd-license.php)
 * 
 * Copyright (c) 2010-2011 Florent Pillet All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of  source code  must retain  the above  copyright notice,
 * this list of  conditions and the following  disclaimer. Redistributions in
 * binary  form must  reproduce  the  above copyright  notice,  this list  of
 * conditions and the following disclaimer  in the documentation and/or other
 * materials  provided with  the distribution.  Neither the  name of  Florent
 * Pillet nor the names of its contributors may be used to endorse or promote
 * products  derived  from  this  software  without  specific  prior  written
 * permission.  THIS  SOFTWARE  IS  PROVIDED BY  THE  COPYRIGHT  HOLDERS  AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT
 * NOT LIMITED TO, THE IMPLIED  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A  PARTICULAR PURPOSE  ARE DISCLAIMED.  IN  NO EVENT  SHALL THE  COPYRIGHT
 * HOLDER OR  CONTRIBUTORS BE  LIABLE FOR  ANY DIRECT,  INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY,  OR CONSEQUENTIAL DAMAGES (INCLUDING,  BUT NOT LIMITED
 * TO, PROCUREMENT  OF SUBSTITUTE GOODS  OR SERVICES;  LOSS OF USE,  DATA, OR
 * PROFITS; OR  BUSINESS INTERRUPTION)  HOWEVER CAUSED AND  ON ANY  THEORY OF
 * LIABILITY,  WHETHER  IN CONTRACT,  STRICT  LIABILITY,  OR TORT  (INCLUDING
 * NEGLIGENCE  OR OTHERWISE)  ARISING  IN ANY  WAY  OUT OF  THE  USE OF  THIS
 * SOFTWARE,   EVEN  IF   ADVISED  OF   THE  POSSIBILITY   OF  SUCH   DAMAGE.
 * 
 */
#import <unistd.h>
#import <pthread.h>
#import <libkern/OSAtomic.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#if !TARGET_OS_IPHONE
#import <CoreServices/CoreServices.h>
#endif

// This define is here so that user application can test whether NSLogger Client is
// being included in the project, and potentially configure their macros accordingly
#define NSLOGGER_WAS_HERE		1

// Set this to 0 if you absolutely NOT want any access to Cocoa (Objective-C, NS* calls)
// We need a couple ones to reliably obtain the thread number and device information
// Note that since we need NSAutoreleasePool when using Cocoa in the logger's worker thread,
// we need to put Cocoa in multithreading mode. Also, ALLOW_COCOA_USE allows the client code
// to use NSLog()-style message formatting (less verbose than CFShow()-style) through the
// use of -[NSString stringWithFormat:arguments:]
#define	ALLOW_COCOA_USE			1

/* -----------------------------------------------------------------
 * Logger option flags & default options
 * -----------------------------------------------------------------
 */
enum {
	kLoggerOption_LogToConsole						= 0x01,
	kLoggerOption_BufferLogsUntilConnection			= 0x02,
	kLoggerOption_BrowseBonjour						= 0x04,
	kLoggerOption_BrowseOnlyLocalDomain				= 0x08,
	kLoggerOption_UseSSL							= 0x10
};

#define LOGGER_DEFAULT_OPTIONS	(kLoggerOption_BufferLogsUntilConnection |	\
								 kLoggerOption_BrowseBonjour |				\
								 kLoggerOption_BrowseOnlyLocalDomain |		\
								 kLoggerOption_UseSSL)

/* -----------------------------------------------------------------
 * Structure defining a Logger
 * -----------------------------------------------------------------
 */
typedef struct
{
	CFStringRef bufferFile;							// If non-NULL, all buffering is done to the specified file instead of in-memory
	CFStringRef host;								// Viewer host to connect to (instead of using Bonjour)
	UInt32 port;									// port on the viewer host

	CFMutableArrayRef bonjourServiceBrowsers;		// Active service browsers
	CFMutableArrayRef bonjourServices;				// Services being tried
	CFNetServiceBrowserRef bonjourDomainBrowser;	// Domain browser
	
	CFMutableArrayRef logQueue;						// Message queue
	pthread_mutex_t logQueueMutex;
	pthread_cond_t logQueueEmpty;
	
	pthread_t workerThread;							// The worker thread responsible for Bonjour resolution, connection and logs transmission
	CFRunLoopSourceRef messagePushedSource;			// A message source that fires on the worker thread when messages are available for send
	CFRunLoopSourceRef bufferFileChangedSource;		// A message source that fires on the worker thread when the buffer file configuration changes

	CFWriteStreamRef logStream;						// The connected stream we're writing to
	CFWriteStreamRef bufferWriteStream;				// If bufferFile not NULL and we're not connected, points to a stream for writing log data
	CFReadStreamRef bufferReadStream;				// If bufferFile not NULL, points to a read stream that will be emptied prior to sending the rest of in-memory messages
	
	SCNetworkReachabilityRef reachability;			// The reachability object we use to determine when the target host becomes reachable
	CFRunLoopTimerRef checkHostTimer;				// A timer to regularly check connection to the defined host, along with reachability for added reliability

	uint8_t *sendBuffer;							// data waiting to be sent
	NSUInteger sendBufferSize;
	NSUInteger sendBufferUsed;						// number of bytes of the send buffer currently in use
	NSUInteger sendBufferOffset;					// offset in sendBuffer to start sending at
	
	int32_t messageSeq;								// sequential message number (added to each message sent)

	// settings
	uint32_t options;								// Flags, see enum above
	CFStringRef bonjourServiceType;					// leave NULL to use the default
	CFStringRef bonjourServiceName;					// leave NULL to use the first one available

	// internal state
	BOOL connected;									// Set to YES once the write stream declares the connection open
	volatile BOOL quit;								// Set to YES to terminate the logger worker thread's runloop
	BOOL incompleteSendOfFirstItem;					// set to YES if we are sending the first item in the queue and it's bigger than what the buffer can hold
} Logger;


/* -----------------------------------------------------------------
 * LOGGING FUNCTIONS
 * -----------------------------------------------------------------
 */

#ifdef __cplusplus
extern "C" {
#endif

// Functions to set and get the default logger
extern void LoggerSetDefaultLogger(Logger *aLogger);
extern Logger *LoggerGetDefaultLogger();

// Initialize a new logger, set as default logger if this is the first one
// Options default to:
// - logging to console = NO
// - buffer until connection = YES
// - browse Bonjour = YES
// - browse only locally on Bonjour = YES
extern Logger* LoggerInit();

// Set logger options if you don't want the default options (see above)
extern void LoggerSetOptions(Logger *logger, uint32_t options);

// Set Bonjour logging names, so you can force the logger to use a specific service type
// or direct logs to the machine on your network which publishes a specific name
extern void LoggerSetupBonjour(Logger *logger, CFStringRef bonjourServiceType, CFStringRef bonjourServiceName);

// Directly set the viewer host (hostname or IP address) and port we want to connect to. If set, LoggerStart() will
// try to connect there first before trying Bonjour
extern void LoggerSetViewerHost(Logger *logger, CFStringRef hostName, UInt32 port);


// Configure the logger to use a local file for buffering, instead of memory.
// - If you initially set a buffer file after logging started but while a logger connection
//   has not been acquired, the contents of the log queue will be written to the buffer file
//	 the next time a logging function is called, or when LoggerStop() is called.
// - If you want to change the buffering file after logging started, you should first
//   call LoggerStop() the call LoggerSetBufferFile(). Note that all logs stored in the previous
//   buffer file WON'T be transferred to the new file in this case.
extern void LoggerSetBufferFile(Logger *logger, CFStringRef absolutePath);

// Activate the logger, try connecting
extern void LoggerStart(Logger *logger);

//extern void LoggerConnectToHost(CFDataRef address, int port);

// Deactivate and free the logger.
extern void LoggerStop(Logger *logger);

// Pause the current thread until all messages from the logger have been transmitted
// this is useful to use before an assert() aborts your program. If waitForConnection is YES,
// LoggerFlush() will block even if the client is not currently connected to the desktop
// viewer. You should be using NO most of the time, but in some cases it can be useful.
extern void LoggerFlush(Logger *logger, BOOL waitForConnection);

/* Logging functions. Each function exists in four versions:
 *
 * - one without a Logger instance (uses default logger) and without filename/line/function (no F suffix)
 * - one without a Logger instance but with filename/line/function (F suffix)
 * - one with a Logger instance (use a specific Logger) and without filename/line/function (no F suffix)
 * - one with a Logger instance (use a specific Logger) and with filename/line/function (F suffix)
 *
 * The exception being the single LogMessageCompat() function which is designed to be a drop-in replacement for NSLog()
 *
 */

// Log a message, calling format compatible with NSLog
extern void LogMessageCompat(NSString *format, ...);

// Log a message. domain can be nil if default domain.
extern void LogMessage(NSString *domain, int level, NSString *format, ...);
extern void LogMessageF(const char *filename, int lineNumber, const char *functionName, NSString *domain, int level, NSString *format, ...);
extern void LogMessageTo(Logger *logger, NSString *domain, int level, NSString *format, ...);
extern void LogMessageToF(Logger *logger, const char *filename, int lineNumber, const char *functionName, NSString *domain, int level, NSString *format, ...);

// Log a message. domain can be nil if default domain (versions with va_list format args instead of ...)
extern void LogMessage_va(NSString *domain, int level, NSString *format, va_list args);
extern void LogMessageF_va(const char *filename, int lineNumber, const char *functionName, NSString *domain, int level, NSString *format, va_list args);
extern void LogMessageTo_va(Logger *logger, NSString *domain, int level, NSString *format, va_list args);
extern void LogMessageToF_va(Logger *logger, const char *filename, int lineNumber, const char *functionName, NSString *domain, int level, NSString *format, va_list args);

// Send binary data to remote logger
extern void LogData(NSString *domain, int level, NSData *data);
extern void LogDataF(const char *filename, int lineNumber, const char *functionName, NSString *domain, int level, NSData *data);
extern void LogDataTo(Logger *logger, NSString *domain, int level, NSData *data);
extern void LogDataToF(Logger *logger, const char *filename, int lineNumber, const char *functionName, NSString *domain, int level, NSData *data);

// Send image data to remote logger
extern void LogImageData(NSString *domain, int level, int width, int height, NSData *data);
extern void LogImageDataF(const char *filename, int lineNumber, const char *functionName, NSString *domain, int level, int width, int height, NSData *data);
extern void LogImageDataTo(Logger *logger, NSString *domain, int level, int width, int height, NSData *data);
extern void LogImageDataToF(Logger *logger, const char *filename, int lineNumber, const char *functionName, NSString *domain, int level, int width, int height, NSData *data);

// Mark the start of a block. This allows the remote logger to group blocks together
extern void LogStartBlock(NSString *format, ...);
extern void LogStartBlockTo(Logger *logger, NSString *format, ...);

// Mark the end of a block
extern void LogEndBlock();
extern void LogEndBlockTo(Logger *logger);
	
#ifdef __cplusplus
};
#endif
