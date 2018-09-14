// UIImageView+AFNetworking.m
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
#import <objc/runtime.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#import "UIImageView+AFRKNetworking.h"

@interface AFRKImageCache : NSCache
- (UIImage *)cachedImageForRequest:(NSURLRequest *)request;
- (void)cacheImage:(UIImage *)image
        forRequest:(NSURLRequest *)request;
@end

#pragma mark -

static char kAFRKImageRequestOperationObjectKey;

@interface UIImageView (_AFRKNetworking)
@property (readwrite, nonatomic, strong, setter = afrk_setImageRequestOperation:) AFRKImageRequestOperation *afrk_imageRequestOperation;
@end

@implementation UIImageView (_AFRKNetworking)
@dynamic afrk_imageRequestOperation;
@end

#pragma mark -

@implementation UIImageView (AFRKNetworking)

- (AFRKHTTPRequestOperation *)afrk_imageRequestOperation {
    return (AFRKHTTPRequestOperation *)objc_getAssociatedObject(self, &kAFRKImageRequestOperationObjectKey);
}

- (void)afrk_setImageRequestOperation:(AFRKImageRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, &kAFRKImageRequestOperationObjectKey, imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSOperationQueue *)afrk_sharedImageRequestOperationQueue {
    static NSOperationQueue *_afrk_imageRequestOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _afrk_imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_afrk_imageRequestOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    });

    return _afrk_imageRequestOperationQueue;
}

+ (AFRKImageCache *)afrk_sharedImageCache {
    static AFRKImageCache *_afrk_imageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _afrk_imageCache = [[AFRKImageCache alloc] init];
    });

    return _afrk_imageCache;
}

#pragma mark -

- (void)afrk_setImageWithURL:(NSURL *)url {
    [self afrk_setImageWithURL:url placeholderImage:nil];
}

- (void)afrk_setImageWithURL:(NSURL *)url
       placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];

    [self afrk_setImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)afrk_setImageWithURLRequest:(NSURLRequest *)urlRequest
              placeholderImage:(UIImage *)placeholderImage
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self afrk_cancelImageRequestOperation];

    UIImage *cachedImage = [[[self class] afrk_sharedImageCache] cachedImageForRequest:urlRequest];
    if (cachedImage) {
        self.afrk_imageRequestOperation = nil;

        if (success) {
            success(urlRequest, nil, cachedImage);
        } else {
            self.image = cachedImage;
        }
    } else {
        if (placeholderImage) {
            self.image = placeholderImage;
        }

        AFRKImageRequestOperation *requestOperation = [[AFRKImageRequestOperation alloc] initWithRequest:urlRequest];
		
#ifdef _AFRKNETWORKING_ALLOW_INVALID_SSL_CERTIFICATES_
		requestOperation.allowsInvalidSSLCertificate = YES;
#endif
		
        [requestOperation setCompletionBlockWithSuccess:^(AFRKHTTPRequestOperation *operation, id responseObject) {
            if ([urlRequest isEqual:[self.afrk_imageRequestOperation request]]) {
                if (self.afrk_imageRequestOperation == operation) {
                    self.afrk_imageRequestOperation = nil;
                }

                if (success) {
                    success(operation.request, operation.response, responseObject);
                } else if (responseObject) {
                    self.image = responseObject;
                }
            }

            [[[self class] afrk_sharedImageCache] cacheImage:responseObject forRequest:urlRequest];
        } failure:^(AFRKHTTPRequestOperation *operation, NSError *error) {
            if ([urlRequest isEqual:[self.afrk_imageRequestOperation request]]) {
                if (self.afrk_imageRequestOperation == operation) {
                    self.afrk_imageRequestOperation = nil;
                }

                if (failure) {
                    failure(operation.request, operation.response, error);
                }
            }
        }];

        self.afrk_imageRequestOperation = requestOperation;

        [[[self class] afrk_sharedImageRequestOperationQueue] addOperation:self.afrk_imageRequestOperation];
    }
}

- (void)afrk_cancelImageRequestOperation {
    [self.afrk_imageRequestOperation cancel];
    self.afrk_imageRequestOperation = nil;
}

@end

#pragma mark -

static inline NSString * AFRKImageCacheKeyFromURLRequest(NSURLRequest *request) {
    return [[request URL] absoluteString];
}

@implementation AFRKImageCache

- (UIImage *)cachedImageForRequest:(NSURLRequest *)request {
    switch ([request cachePolicy]) {
        case NSURLRequestReloadIgnoringCacheData:
        case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
            return nil;
        default:
            break;
    }

	return [self objectForKey:AFRKImageCacheKeyFromURLRequest(request)];
}

- (void)cacheImage:(UIImage *)image
        forRequest:(NSURLRequest *)request
{
    if (image && request) {
        [self setObject:image forKey:AFRKImageCacheKeyFromURLRequest(request)];
    }
}

@end

#endif
