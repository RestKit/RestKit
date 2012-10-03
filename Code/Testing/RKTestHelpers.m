//
//  RKTestHelpers.m
//  RestKit
//
//  Created by Blake Watters on 10/2/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKTestHelpers.h"
#import "RKObjectManager.h"
#import "RKRoute.h"
#import "RKPathUtilities.h"
#import "RKLog.h"

@implementation RKTestHelpers

+ (RKRoute *)stubRouteForClass:(Class)objectClass method:(RKRequestMethod)method withPathPattern:(NSString *)pathPattern onObjectManager:(RKObjectManager *)nilOrObjectManager
{
    RKObjectManager *objectManager = nilOrObjectManager ?: [RKObjectManager sharedManager];
    RKRoute *route = [objectManager.router.routeSet routeForClass:objectClass method:method];
    NSAssert(route, @"Expected to retrieve a route, but got nil");
    [objectManager.router.routeSet removeRoute:route];
    RKRoute *stubbedRoute = [RKRoute routeWithClass:objectClass pathPattern:pathPattern method:method];
    [objectManager.router.routeSet addRoute:stubbedRoute];
    return stubbedRoute;
}

+ (RKRoute *)stubRouteNamed:(NSString *)routeName withPathPattern:(NSString *)pathPattern onObjectManager:(RKObjectManager *)nilOrObjectManager
{
    RKObjectManager *objectManager = nilOrObjectManager ?: [RKObjectManager sharedManager];
    RKRoute *route = [[RKObjectManager sharedManager].router.routeSet routeForName:routeName];
    NSAssert(route, @"Expected to retrieve a route, but got nil");
    [[RKObjectManager sharedManager].router.routeSet removeRoute:route];
    RKRoute *stubbedRoute = [RKRoute routeWithName:routeName pathPattern:pathPattern method:route.method];
    [[RKObjectManager sharedManager].router.routeSet addRoute:stubbedRoute];
    [self copyFetchRequestBlocksMatchingPathPattern:route.pathPattern toBlocksMatchingRelativeString:pathPattern onObjectManager:objectManager];
    return stubbedRoute;
}

+ (RKRoute *)stubRouteForRelationship:(NSString *)relationshipName ofClass:(Class)objectClass pathPattern:(NSString *)pathPattern onObjectManager:(RKObjectManager *)nilOrObjectManager
{
    RKObjectManager *objectManager = nilOrObjectManager ?: [RKObjectManager sharedManager];
    RKRoute *route = [objectManager.router.routeSet routeForRelationship:relationshipName ofClass:objectClass method:RKRequestMethodGET];
    NSAssert(route, @"Expected to retrieve a route, but got nil");
    [objectManager.router.routeSet removeRoute:route];
    RKRoute *stubbedRoute = [RKRoute routeWithRelationshipName:relationshipName objectClass:objectClass pathPattern:pathPattern method:RKRequestMethodGET];
    [objectManager.router.routeSet addRoute:stubbedRoute];
    [self copyFetchRequestBlocksMatchingPathPattern:route.pathPattern toBlocksMatchingRelativeString:pathPattern onObjectManager:objectManager];
    return stubbedRoute;
}

+ (void)copyFetchRequestBlocksMatchingPathPattern:(NSString *)pathPattern
                   toBlocksMatchingRelativeString:(NSString *)relativeString
                                  onObjectManager:(RKObjectManager *)nilOrObjectManager
{
    RKObjectManager *objectManager = nilOrObjectManager ?: [RKObjectManager sharedManager];
    NSURL *URL = [NSURL URLWithString:pathPattern relativeToURL:objectManager.HTTPClient.baseURL];
    for (RKFetchRequestBlock block in objectManager.fetchRequestBlocks) {
        NSFetchRequest *fetchRequest = block(URL);
        if (fetchRequest) {
            // Add a new block that matches our stubbed path
            [[RKObjectManager sharedManager] addFetchRequestBlock:^NSFetchRequest *(NSURL *URL) {
                // TODO: Note that relativeString does not work because NSURLRequest drops the relative parent of the URL
                //                if ([[URL relativeString] isEqualToString:relativeString]) {
                if ([[URL path] isEqualToString:relativeString]) {
                    return fetchRequest;
                }
                
                return nil;
            }];
            
            break;
        }
    }
}

+ (void)clearCacheDirectory
{
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    
    NSError *error = nil;
    NSString *cachePath = RKCachesDirectory();
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:cachePath error:&error];
    if (success) {
        RKLogDebug(@"Cleared cache directory...");
        success = [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            RKLogError(@"Failed creation of cache path '%@': %@", cachePath, [error localizedDescription]);
        }
    } else {
        RKLogError(@"Failed to clear cache path '%@': %@", cachePath, [error localizedDescription]);
    }
}

@end
