//
//  AFRKNetworkingTests.m
//  RestKitTests
//
//  Created by Tyler Milner on 3/2/18.
//  Copyright © 2018 RestKit. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIImageView+AFRKNetworking.h"

// Re-defining the interface for AFRKImageCache since it's only privately declared in UIImageView+AFRKNetworking.m.
@interface AFRKImageCache : NSCache
- (UIImage *)cachedImageForRequest:(NSURLRequest *)request;
- (void)cacheImage:(UIImage *)image
        forRequest:(NSURLRequest *)request;
@end

// Also re-defining the interface for accessing the image cache since it's only privately declared in UIImageView+AFRKNetworking.m.
@interface UIImageView (AFRKNetworking_Tests)
+ (AFRKImageCache *)afrk_sharedImageCache;
@end

@interface AFRKNetworkingTests : XCTestCase

@end

@implementation AFRKNetworkingTests

- (void)testSetImageWithURLReturnsURLRequestInCompletionBlockWhenImageIsFetchedFromCache
{
    // Arrange
    NSURL *imageURL = [[NSURL alloc] initWithString:@"https://test.com/image.png"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:imageURL];
    
    UIImage *testImage = [[UIImage alloc] init];
    
    AFRKImageCache *cache = [UIImageView afrk_sharedImageCache];
    [cache cacheImage:testImage forRequest:request];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    
    // Act
    XCTestExpectation *asyncExpectation = [self expectationWithDescription:@"image view loads"];
    
    [imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        XCTAssertNotNil(request);
        [asyncExpectation fulfill];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        XCTFail("%@ should succeed", NSStringFromSelector(@selector(setImageWithURLRequest:placeholderImage:success:failure:)));
        [asyncExpectation fulfill];
    }];
    
    // Assert
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

@end
