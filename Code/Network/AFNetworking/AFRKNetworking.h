// AFNetworking.h
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <Availability.h>

#if __IPHONE_OS_VERSION_MIN_REQUIRED
    #import <SystemConfiguration/SystemConfiguration.h>
    #import <MobileCoreServices/MobileCoreServices.h>
    #import <Security/Security.h>
#else
    #import <SystemConfiguration/SystemConfiguration.h>
    #import <CoreServices/CoreServices.h>
    #import <Security/Security.h>
#endif

#ifndef _AFRKNETWORKING_
    #define _AFRKNETWORKING_
    #define _AFRKNETWORKING_PIN_SSL_CERTIFICATES_

    #import "AFRKURLConnectionOperation.h"

    #import "AFRKHTTPRequestOperation.h"
    #import "AFRKJSONRequestOperation.h"
    #import "AFRKXMLRequestOperation.h"
    #import "AFRKPropertyListRequestOperation.h"
    #import "AFRKHTTPClient.h"

    #import "AFRKImageRequestOperation.h"

    #if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        #import "AFRKNetworkActivityIndicatorManager.h"
        #import "UIImageView+AFRKNetworking.h"
    #endif
#endif /* _AFNETWORKING_ */
