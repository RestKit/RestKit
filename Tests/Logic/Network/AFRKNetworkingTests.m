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

@property (nonatomic, strong) UIImage *testImage;

@end

@implementation AFRKNetworkingTests

#pragma mark - Lifecycle

- (void)setUp
{
    [super setUp];
    
    self.testImage = [[UIImage alloc] init];
}

- (void)tearDown
{
    self.testImage = nil;
    
    [super tearDown];
}

#pragma mark - Tests

// Success block NSURLRequest parameter
- (void)testSetImageWithURLReturnsURLRequestInCompletionBlockWhenImageIsFetchedFromCache
{
    [self performMockCachedSetImageWithURLRequestCallWithSuccessAssertion:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        expect(request).toNot.equal(nil);
    } failureAssertion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        failure(@"image request should always succeed for this test");
    }];
}

// Success block NSHTTPURLResponse parameter
- (void)testSetImageWithURLReturnsNilURLResponseInCompletionBlockWhenImageIsFetchedFromCache
{
    [self performMockCachedSetImageWithURLRequestCallWithSuccessAssertion:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        expect(response).to.equal(nil);
    } failureAssertion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        failure(@"image request should always succeed for this test");
    }];
}

// Success block UIImage parameter
- (void)testSetImageWithURLReturnsImageInCompletionBlockWhenImageIsFetchedFromCache
{
    [self performMockCachedSetImageWithURLRequestCallWithSuccessAssertion:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        expect(image).to.equal(self.testImage);
    } failureAssertion:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        failure(@"image request should always succeed for this test");
    }];
}

#pragma mark - Private

- (void)performMockCachedSetImageWithURLRequestCallWithSuccessAssertion:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))successAssertion failureAssertion:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failureAssertion
{
    // Arrange
    // Create dummy request
    NSURL *imageURL = [[NSURL alloc] initWithString:@"https://test.com/image.png"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:imageURL];
    
    // Side-load the test image into the cache
    AFRKImageCache *cache = [UIImageView afrk_sharedImageCache];
    [cache cacheImage:self.testImage forRequest:request];
    
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
