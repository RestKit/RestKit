/*
 *  FileMD5Hash.h
 *  FileMD5Hash
 * 
 *  Copyright © 2010 Joel Lopes Da Silva. All rights reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 * 
 *        http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#ifndef FILEMD5HASH_H
#define FILEMD5HASH_H

// Target conditionals
#include <TargetConditionals.h>

// General imports for Objective-C
#ifdef __OBJC__
#if TARGET_OS_IPHONE
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif
#endif


//---------------------------------------------------------
// Macros
//---------------------------------------------------------

// Extern
#if defined(__cplusplus)
#define FILEMD5HASH_EXTERN extern "C"
#else
#define FILEMD5HASH_EXTERN extern
#endif

//---------------------------------------------------------
// Includes
//---------------------------------------------------------

// Core Foundation
#include <CoreFoundation/CoreFoundation.h>


//---------------------------------------------------------
// Constant declaration
//---------------------------------------------------------

// In bytes
#define FileHashDefaultChunkSizeForReadingData 4096


//---------------------------------------------------------
// Function declaration
//---------------------------------------------------------

FILEMD5HASH_EXTERN CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath, 
                                                         size_t chunkSizeForReadingData);


#endif
