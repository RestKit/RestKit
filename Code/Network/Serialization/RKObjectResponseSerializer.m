//
//  RKObjectResponseSerializer.m
//  RestKit
//
//  Created by Blake Watters on 11/16/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKObjectResponseSerializer.h"
#import "RKResponseMapperOperation.h"

@interface RKObjectResponseSerializer ()
@property (nonatomic, strong) NSMutableArray *mutableResponseDescriptors;
@end

@implementation RKObjectResponseSerializer

- (id)init
{
    self = [super init];
    if (self) {
        self.mutableResponseDescriptors = [NSMutableArray new];
        self.contentResponseSerializer = [AFJSONResponseSerializer serializer];
    }
    return self;
}

#pragma mark - NSCoding

//- (id)initWithCoder:(NSCoder *)decoder
//{
//    self = [self init];
//    if (!self) {
//        return nil;
//    }
//
//    self.acceptableStatusCodes = [decoder decodeObjectForKey:NSStringFromSelector(@selector(acceptableStatusCodes))];
//    self.acceptableContentTypes = [decoder decodeObjectForKey:NSStringFromSelector(@selector(acceptableContentTypes))];
//
//    return self;
//}
//
//- (void)encodeWithCoder:(NSCoder *)coder
//{
//    [coder encodeObject:self.acceptableStatusCodes forKey:NSStringFromSelector(@selector(acceptableStatusCodes))];
//    [coder encodeObject:self.acceptableContentTypes forKey:NSStringFromSelector(@selector(acceptableContentTypes))];
//}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    RKObjectResponseSerializer *serializer = (RKObjectResponseSerializer *)[super copyWithZone:zone];
    serializer.contentResponseSerializer = self.contentResponseSerializer;
    [serializer addResponseDescriptorsFromArray:self.responseDescriptors];
    return serializer;
}

- (NSArray *)responseDescriptors
{
    return [NSArray arrayWithArray:self.mutableResponseDescriptors];
}

- (void)addResponseDescriptor:(RKResponseDescriptor *)responseDescriptor
{
    NSParameterAssert(responseDescriptor);
    NSAssert([responseDescriptor isKindOfClass:[RKResponseDescriptor class]], @"Expected an object of type RKResponseDescriptor, got '%@'", [responseDescriptor class]);
//    responseDescriptor.baseURL = self.baseURL;
    [self.mutableResponseDescriptors addObject:responseDescriptor];
}

- (void)addResponseDescriptorsFromArray:(NSArray *)responseDescriptors
{
    for (RKResponseDescriptor *responseDescriptor in responseDescriptors) {
        [self addResponseDescriptor:responseDescriptor];
    }
}

- (void)removeResponseDescriptor:(RKResponseDescriptor *)responseDescriptor
{
    NSParameterAssert(responseDescriptor);
    NSAssert([responseDescriptor isKindOfClass:[RKResponseDescriptor class]], @"Expected an object of type RKResponseDescriptor, got '%@'", [responseDescriptor class]);
    [self.mutableResponseDescriptors removeObject:responseDescriptor];
}

#pragma mark -

- (NSSet *)acceptableContentTypes
{
    return [self.contentResponseSerializer isKindOfClass:[AFHTTPResponseSerializer class]]
    ? [(AFHTTPResponseSerializer *)self.contentResponseSerializer acceptableContentTypes]
    : nil;
}

//- (BOOL)validateResponse:(NSHTTPURLResponse *)response
//                    data:(NSData *)data
//                   error:(NSError *__autoreleasing *)error
//{
//}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                        request:(NSURLRequest *)request
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data request:request error:error]) {
        if ([(NSError *)(*error) code] == NSURLErrorCannotDecodeContentData) {
            return nil;
        }
    }

    RKObjectResponseMapperOperation *mapperOperation = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:(NSHTTPURLResponse *)response data:data responseDescriptors:self.responseDescriptors];
    mapperOperation.targetObject = self.targetObject;
    mapperOperation.contentSerializer = self.contentResponseSerializer;
    [mapperOperation start];
    if (mapperOperation.error) {
        *error = mapperOperation.error;
        return nil;
    }
    return mapperOperation.mappingResult;
}

@end
