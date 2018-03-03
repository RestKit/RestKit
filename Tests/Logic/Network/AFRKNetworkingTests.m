//
//  AFRKNetworkingTests.m
//  RestKitTests
//
//  Created by Tyler Milner on 3/2/18.
//  Copyright © 2018 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
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

#pragma mark - Tests

- (void)testSetImageWithURLReturnsURLRequestInCompletionBlockWhenImageIsFetchedFromCache
{
    [self performMockCachedSetImageWithURLRequestCallWithSuccessAssertion:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        expect(request).toNot.equal(nil);
    } failureAssertion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        failure(@"image request should always succeed for this test");
    }];
}

- (void)testSetImageWithURLReturnsNilURLResponseInCompletionBlockWhenImageIsFetchedFromCache
{
    
}

- (void)testSetImageWithURLReturnsImageInCompletionBlockWhenImageIsFetchedFromCache
{
    
}

#pragma mark - Private

- (void)performMockCachedSetImageWithURLRequestCallWithSuccessAssertion:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))successAssertion failureAssertion:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failureAssertion
{
    // Act
    // Create dummy request and image
    NSURL *imageURL = [[NSURL alloc] initWithString:@"https://test.com/image.png"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:imageURL];
    
    UIImage *testImage = [[UIImage alloc] init];
    
    // Side-load the image into the cache
    AFRKImageCache *cache = [UIImageView afrk_sharedImageCache];
    [cache cacheImage:testImage forRequest:request];
    
    // Setup the System Under Test
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    
    // Act
    // Call 'setImageWithURLRequest:placeholderImage:success:failure:'
    // Run the provided assertion blocks inside of their respective completion blocks
    XCTestExpectation *asyncExpectation = [self expectationWithDescription:@"image view loads"];
    
    [imageView setImageWithURLRequest:request placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        successAssertion(request, response, image);
        [asyncExpectation fulfill];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        failureAssertion(request, response, error);
        [asyncExpectation fulfill];
    }];
    
    // Assert
    // Assertion blocks should have been run
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

@end
