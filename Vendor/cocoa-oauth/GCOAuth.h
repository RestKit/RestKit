/*
 
 Copyright 2011 TweetDeck Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
 this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY TWEETDECK INC. ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL TWEETDECK INC. OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
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

#import <Foundation/Foundation.h>

/*
 This OAuth implementation doesn't cover the whole spec (eg. it’s HMAC only).
 But you'll find it works with almost all the OAuth implementations you need
 to interact with in the wild. How ace is that?!
 */
@interface GCOAuth : NSObject {
@private
    NSString *signatureSecret;
    NSDictionary *OAuthParameters;
}

/*
 Set the user agent to be used for all requests.
 */
+ (void)setUserAgent:(NSString *)agent;

/*
 Set the time offset to be used for timestamp calculations.
 */
+ (void)setTimeStampOffset:(time_t)offset;

/*
 Control HTTPS cookie storage for all generated requests
 */
+ (void)setHTTPShouldHandleCookies:(BOOL)handle;

/**
 Creates and returns a URL request that will perform an HTTP operation for the given method. All
 of the appropriate fields will be parameter encoded as necessary so do not
 encode them yourself. The contents of the parameters dictionary must be string
 key/value pairs. You are contracted to consume the NSURLRequest *immediately*.
 */
+ (NSURLRequest *)URLRequestForPath:(NSString *)path
                         HTTPMethod:(NSString *)HTTPMethod
                         parameters:(NSDictionary *)parameters
                             scheme:(NSString *)scheme
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret;

/*
 Creates and returns a URL request that will perform a GET HTTP operation. All
 of the appropriate fields will be parameter encoded as necessary so do not
 encode them yourself. The contents of the parameters dictionary must be string
 key/value pairs. You are contracted to consume the NSURLRequest *immediately*.
 */
+ (NSURLRequest *)URLRequestForPath:(NSString *)path
                      GETParameters:(NSDictionary *)parameters
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret;

/*
 Performs the same operation as the above method but allows a customizable URL
 scheme, e.g. HTTPS.
 */
+ (NSURLRequest *)URLRequestForPath:(NSString *)path
                      GETParameters:(NSDictionary *)parameters
                             scheme:(NSString *)scheme
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret;

/*
 Creates and returns a URL request that will perform a POST HTTP operation. All
 data will be sent as form URL encoded. Restrictions on the arguments to this
 method are the same as the GET request methods.
 */
+ (NSURLRequest *)URLRequestForPath:(NSString *)path
                     POSTParameters:(NSDictionary *)parameters
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret;

/*
 Performs the same operation as the above method but allows a customizable URL
 scheme, e.g. HTTPS.
 */
+ (NSURLRequest *)URLRequestForPath:(NSString *)path
                     POSTParameters:(NSDictionary *)parameters
                             scheme:(NSString *)scheme
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret;
@end

@interface NSString (GCOAuthAdditions)

// better percent escape
- (NSString *)pcen;
@end

@interface NSURL (GCOAuthURL)

/*
 Get host:port from URL unless port is 80 or 443 (http://tools.ietf.org/html/rfc5849#section-3.4.1.2). Otherwis reurn only host.
 */
- (NSString *)hostAndPort;
@end
/*
 
 XAuth example (because you may otherwise be scratching your head):

    NSURLRequest *xauth = [GCOAuth URLRequestForPath:@"/oauth/access_token"
                                      POSTParameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                      username, @"x_auth_username",
                                                      password, @"x_auth_password",
                                                      @"client_auth", @"x_auth_mode",
                                                      nil]
                                                host:@"api.twitter.com"
                                         consumerKey:CONSUMER_KEY
                                      consumerSecret:CONSUMER_SECRET
                                         accessToken:nil
                                         tokenSecret:nil];

 OAuth Echo example (we have found that some consumers require HTTPS for the
 echo, so to be safe we always do it):

    NSURLRequest *echo = [GCOAuth URLRequestForPath:@"/1/account/verify_credentials.json"
                                      GETParameters:nil
                                             scheme:@"https"
                                               host:@"api.twitter.com"
                                        consumerKey:CONSUMER_KEY
                                     consumerSecret:CONSUMER_SECRET
                                        accessToken:accessToken
                                        tokenSecret:tokenSecret];
    NSMutableURLRequest *rq = [NSMutableURLRequest new];
    [rq setValue:[[echo URL] absoluteString] forHTTPHeaderField:@"X-Auth-Service-Provider"];
    [rq setValue:[echo valueForHTTPHeaderField:@"Authorization"] forHTTPHeaderField:@"X-Verify-Credentials-Authorization"];
    // Now consume rq with an NSURLConnection
    [rq release];
 
 
 Suggested usage would be to make some categories for this class that
 automatically adds both secrets, both tokens and host information. This
 makes usage less cumbersome. Eg:
 
    [TwitterOAuth GET:@"/1/statuses/home_timeline.json"];
    [TwitterOAuth GET:@"/1/statuses/home_timeline.json" queryParameters:dictionary];
 
 At TweetDeck we have TDAccount classes that represent separate user logins
 for different services when instantiated.
 
*/
