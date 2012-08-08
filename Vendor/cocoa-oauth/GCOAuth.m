/*
 
 Copyright 2011 TweetDeck Inc. All rights reserved.
 
 Design and implementation, Max Howell, @mxcl.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY TweetDeck Inc. ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL TweetDeck Inc. OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are
 those of the authors and should not be interpreted as representing official
 policies, either expressed or implied, of TweetDeck Inc.
 
 */

#import "GCOAuth.h"

#import <CommonCrypto/CommonHMAC.h>

#import "NSData+Base64.h"

// static variables
static NSString *GCOAuthUserAgent = nil;
static time_t GCOAuthTimeStampOffset = 0;
static BOOL GCOAuthUseHTTPSCookieStorage = YES;

@interface GCOAuth ()

// properties
@property (nonatomic, copy) NSDictionary *requestParameters;
@property (nonatomic, copy) NSString *HTTPMethod;
@property (nonatomic, copy) NSURL *URL;

// get a nonce string
+ (NSString *)nonce;

// get a timestamp string
+ (NSString *)timeStamp;

// generate properly escaped string for the given parameters
+ (NSString *)queryStringFromParameters:(NSDictionary *)parameters;

// create a request with given oauth values
- (id)initWithConsumerKey:(NSString *)consumerKey
           consumerSecret:(NSString *)consumerSecret
              accessToken:(NSString *)accessToken
              tokenSecret:(NSString *)tokenSecret;

// generate a request
- (NSMutableURLRequest *)request;

// generate authorization header
- (NSString *)authorizationHeader;

// generate signature
- (NSString *)signature;

// generate signature base
- (NSString *)signatureBase;
@end

@implementation GCOAuth

@synthesize requestParameters = __parameters;
@synthesize HTTPMethod = __method;
@synthesize URL = __url;

#pragma mark - object methods
- (id)initWithConsumerKey:(NSString *)consumerKey
           consumerSecret:(NSString *)consumerSecret
              accessToken:(NSString *)accessToken
              tokenSecret:(NSString *)tokenSecret {
    self = [super init];
    if (self) {
        OAuthParameters = [[NSDictionary alloc] initWithObjectsAndKeys:
                           [[consumerKey copy] autorelease], @"oauth_consumer_key",
                           [GCOAuth nonce], @"oauth_nonce",
                           [GCOAuth timeStamp], @"oauth_timestamp",
                           @"1.0",  @"oauth_version",
                           @"HMAC-SHA1", @"oauth_signature_method",
                           [[accessToken copy] autorelease], @"oauth_token", // leave accessToken last or you'll break XAuth attempts
                           nil];
        signatureSecret = [[NSString stringWithFormat:@"%@&%@", [consumerSecret pcen], [tokenSecret ?: @"" pcen]] retain];
    }
    return self;
}
- (NSMutableURLRequest *)request {
    NSMutableURLRequest *request = [NSMutableURLRequest
                                    requestWithURL:self.URL
                                    cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                    timeoutInterval:10.0];
    if (GCOAuthUserAgent) {
        [request setValue:GCOAuthUserAgent forHTTPHeaderField:@"User-Agent"];
    }
    [request setValue:[self authorizationHeader] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPMethod:self.HTTPMethod];
    [request setHTTPShouldHandleCookies:GCOAuthUseHTTPSCookieStorage];
    return request;
}
- (NSString *)authorizationHeader {
    NSMutableArray *entries = [NSMutableArray array];
    NSMutableDictionary *dictionary = [OAuthParameters mutableCopy];
    [dictionary setObject:[self signature] forKey:@"oauth_signature"];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *entry = [NSString stringWithFormat:@"%@=\"%@\"", [key pcen], [obj pcen]];
        [entries addObject:entry];
    }];
    [dictionary release];
    return [@"OAuth " stringByAppendingString:[entries componentsJoinedByString:@","]];
}
- (NSString *)signature {
    
    // get signature components
    NSData *base = [[self signatureBase] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *secret = [signatureSecret dataUsingEncoding:NSUTF8StringEncoding];
    
    // hmac
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CCHmacContext cx;
    CCHmacInit(&cx, kCCHmacAlgSHA1, [secret bytes], [secret length]);
    CCHmacUpdate(&cx, [base bytes], [base length]);
    CCHmacFinal(&cx, digest);
    
    // base 64
    NSData *data = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
    return [data base64EncodedString];
    
}
- (NSString *)signatureBase {
    
    // normalize parameters
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters addEntriesFromDictionary:OAuthParameters];
    [parameters addEntriesFromDictionary:self.requestParameters];
    NSMutableArray *entries = [NSMutableArray arrayWithCapacity:[parameters count]];
    NSArray *keys = [[parameters allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        NSString *obj = [parameters objectForKey:key];
        NSString *entry = [NSString stringWithFormat:@"%@=%@", [key pcen], [obj pcen]];
        [entries addObject:entry];
    }
    NSString *normalizedParameters = [entries componentsJoinedByString:@"&"];
    
    // construct request url
    NSURL *URL = self.URL;
    NSString *URLString = [NSString stringWithFormat:@"%@://%@%@",
                           [[URL scheme] lowercaseString],
                           [[URL hostAndPort] lowercaseString],
                           [URL path]];
    
    // create components
    NSArray *components = [NSArray arrayWithObjects:
                           [self.HTTPMethod pcen],
                           [URLString pcen],
                           [normalizedParameters pcen],
                           nil];
    
    // return
    return [components componentsJoinedByString:@"&"];
    
}
- (void)dealloc {
    self.URL = nil;
    self.HTTPMethod = nil;
    self.requestParameters = nil;
    [OAuthParameters release];
    OAuthParameters = nil;
    [signatureSecret release];
    signatureSecret = nil;
    [super dealloc];
}

#pragma mark - class methods
+ (void)setUserAgent:(NSString *)agent {
    [GCOAuthUserAgent release];
    GCOAuthUserAgent = [agent copy];
}
+ (void)setTimeStampOffset:(time_t)offset {
    GCOAuthTimeStampOffset = offset;
}
+ (void)setHTTPShouldHandleCookies:(BOOL)handle {
    GCOAuthUseHTTPSCookieStorage = handle;
}
+ (NSString *)nonce {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return [(NSString *)string autorelease];
}
+ (NSString *)timeStamp {
    time_t t;
    time(&t);
    mktime(gmtime(&t));
    return [NSString stringWithFormat:@"%lu", (t + GCOAuthTimeStampOffset)];
}
+ (NSString *)queryStringFromParameters:(NSDictionary *)parameters {
    NSMutableArray *entries = [NSMutableArray array];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *entry = [NSString stringWithFormat:@"%@=%@", [key pcen], [obj pcen]];
        [entries addObject:entry];
    }];
    return [entries componentsJoinedByString:@"&"];
}
+ (NSURLRequest *)URLRequestForPath:(NSString *)path
                         HTTPMethod:(NSString *)HTTPMethod
                         parameters:(NSDictionary *)parameters
                             scheme:(NSString *)scheme
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret {
    // check parameters
    if (host == nil || path == nil) { return nil; }
    
    // create object
    GCOAuth *oauth = [[GCOAuth alloc] initWithConsumerKey:consumerKey
                                           consumerSecret:consumerSecret
                                              accessToken:accessToken
                                              tokenSecret:tokenSecret];
    oauth.HTTPMethod = HTTPMethod;
    oauth.requestParameters = parameters;
        
    if ([[HTTPMethod uppercaseString] isEqualToString:@"GET"]) {
        // Handle GET
        NSString *encodedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *URLString = [NSString stringWithFormat:@"%@://%@%@", scheme, host, encodedPath];
        if ([oauth.requestParameters count]) {
            NSString *query = [GCOAuth queryStringFromParameters:oauth.requestParameters];
            URLString = [NSString stringWithFormat:@"%@?%@", URLString, query];
        }
        oauth.URL = [NSURL URLWithString:URLString];                
    } else {
        // All other HTTP methods
        NSURL *URL = [[NSURL alloc] initWithScheme:scheme host:host path:path];
        oauth.URL = URL;
        [URL release];                
    }    
    
    NSMutableURLRequest *request = [oauth request];
    if (![[HTTPMethod uppercaseString] isEqualToString:@"GET"] && [oauth.requestParameters count]) {
        // Add the parameters to the request body for non GET requests
        NSString *query = [GCOAuth queryStringFromParameters:oauth.requestParameters];
        NSData *data = [query dataUsingEncoding:NSUTF8StringEncoding];
        NSString *length = [NSString stringWithFormat:@"%lu", (unsigned long)[data length]];
        [request setHTTPBody:data];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setValue:length forHTTPHeaderField:@"Content-Length"];
    }
    
    // return
    [oauth release];
    return request;
}
+ (NSURLRequest *)URLRequestForPath:(NSString *)path
                      GETParameters:(NSDictionary *)parameters
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret {
    return [self URLRequestForPath:path HTTPMethod:@"GET" 
                        parameters:parameters 
                            scheme:@"http" 
                              host:host 
                       consumerKey:consumerKey 
                    consumerSecret:consumerSecret 
                       accessToken:accessToken 
                       tokenSecret:tokenSecret];
}
+ (NSURLRequest *)URLRequestForPath:(NSString *)path
                      GETParameters:(NSDictionary *)parameters
                             scheme:(NSString *)scheme
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret {
    
    return [self URLRequestForPath:path 
                        HTTPMethod:@"GET" 
                        parameters:parameters 
                            scheme:scheme 
                              host:host 
                       consumerKey:consumerKey 
                    consumerSecret:consumerSecret 
                       accessToken:accessToken 
                       tokenSecret:tokenSecret];
}
+ (NSURLRequest *)URLRequestForPath:(NSString *)path
                     POSTParameters:(NSDictionary *)parameters
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret
{
    return [self URLRequestForPath:path 
                        HTTPMethod:@"POST" 
                        parameters:parameters 
                            scheme:@"https" 
                              host:host 
                       consumerKey:consumerKey 
                    consumerSecret:consumerSecret 
                       accessToken:accessToken 
                       tokenSecret:tokenSecret];
}
+ (NSURLRequest *)URLRequestForPath:(NSString *)path
                     POSTParameters:(NSDictionary *)parameters
                             scheme:(NSString *)scheme
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret {
    
    return [self URLRequestForPath:path 
                        HTTPMethod:@"POST" 
                        parameters:parameters 
                            scheme:scheme 
                              host:host 
                       consumerKey:consumerKey 
                    consumerSecret:consumerSecret 
                       accessToken:accessToken 
                       tokenSecret:tokenSecret];
    
}

@end

@implementation NSURL  (GCOAuthURL)
- (NSString *)hostAndPort {
    if ([self port] != nil && [[self port] intValue] != 80 && [[self port] intValue] != 443) {
        return [NSString stringWithFormat:@"%@:%@", [self host], [self port]];
    } else {
        return [self host];
    }
}
@end

@implementation NSString (GCOAuthAdditions)
- (NSString *)pcen {
    CFStringRef string = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                 (CFStringRef)self,
                                                                 NULL,
                                                                 CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                 kCFStringEncodingUTF8);
    return [(NSString *)string autorelease];
}
@end
