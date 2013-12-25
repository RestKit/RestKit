//
//  RKObjectResponseSerializer.m
//  RestKit
//
//  Created by Blake Watters on 11/16/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKResponseSerialization.h"
#import "RKResponseMapperOperation.h"

@interface RKResponseSerializationManager ()
@property (nonatomic, strong) NSMutableArray *mutableResponseDescriptors;
@end

@implementation RKResponseSerializationManager

- (id)init
{
    self = [super init];
    if (self) {
        self.mutableResponseDescriptors = [NSMutableArray new];
    }
    return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [self init];
    if (!self) {
        return nil;
    }

    [self addResponseDescriptors:[decoder decodeObjectForKey:NSStringFromSelector(@selector(responseDescriptors))]];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.responseDescriptors forKey:NSStringFromSelector(@selector(responseDescriptors))];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    RKResponseSerializationManager *serializer = (RKResponseSerializationManager *)[[self class] new];
    [serializer addResponseDescriptors:self.responseDescriptors];
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
    [self.mutableResponseDescriptors addObject:responseDescriptor];
}

- (void)addResponseDescriptors:(NSArray *)responseDescriptors
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

// TODO: Migrate functionality of `appropriateObjectRequestOperation...`
- (RKObjectResponseSerializer *)serializerWithRequest:(NSURLRequest *)request object:(id)object
{
    RKObjectResponseSerializer *responseSerializer = [RKObjectResponseSerializer objectResponseSerializerWithRequest:request responseDescriptors:self.responseDescriptors];
    responseSerializer.targetObject = object;
    return responseSerializer;
}

@end

@interface RKObjectResponseSerializer ()
@property (nonatomic, strong, readwrite) NSURLRequest *request;
@property (nonatomic, copy, readwrite) NSArray *responseDescriptors;
@end

@implementation RKObjectResponseSerializer

+ (instancetype)objectResponseSerializerWithRequest:(NSURLRequest *)request responseDescriptors:(NSArray *)responseDescriptors
{
    RKObjectResponseSerializer *serializer = [self new];
    serializer.request = request;
    serializer.responseDescriptors = responseDescriptors;
    return serializer;
}

#pragma mark - 

//- (NSSet *)acceptableContentTypes
//{
//    return [self.contentResponseSerializer isKindOfClass:[AFHTTPResponseSerializer class]]
//    ? [(AFHTTPResponseSerializer *)self.contentResponseSerializer acceptableContentTypes]
//    : nil;
//}

//- (BOOL)validateResponse:(NSHTTPURLResponse *)response
//                    data:(NSData *)data
//                   error:(NSError *__autoreleasing *)error
//{
//}

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if ([(NSError *)(*error) code] == NSURLErrorCannotDecodeContentData) {
            return nil;
        }
    }

    RKObjectResponseMapperOperation *mapperOperation = [[RKObjectResponseMapperOperation alloc] initWithRequest:self.request response:(NSHTTPURLResponse *)response data:data responseDescriptors:self.responseDescriptors];
    mapperOperation.targetObject = self.targetObject;
//    mapperOperation.contentSerializer = self.contentResponseSerializer;
    [mapperOperation start];
    if (mapperOperation.error) {
        *error = mapperOperation.error;
        return nil;
    }
    return mapperOperation.mappingResult;
}

@end

@implementation RKManagedObjectResponseSerializer
@end
