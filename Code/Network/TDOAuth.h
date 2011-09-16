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

/**
  This OAuth implementation doesn't cover the whole spec (eg. it’s HMAC only).
  But you'll find it works with almost all the OAuth implementations you need
  to interact with in the wild. How ace is that?!
*/

@interface TDOAuth : NSObject {
    NSURL *url;
    NSString *signature_secret;
    NSDictionary *params; // these are pre-percent encoded
    NSString *method;
}

/**
  @p unencodeParameters may be nil. Objects in the dictionary must be strings.
  You are contracted to consume the NSURLRequest *immediately*. Don't put the
  queryParameters in the path as a query string! Path MUST start with a slash!
  Don't percent encode anything!
*/
+ (NSURLRequest *)URLRequestForPath:(NSString *)unencodedPath_WITHOUT_Query
                      GETParameters:(NSDictionary *)unencodedParameters
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret;

/**
  Sometimes the service in question insists on HTTPS for everything. They
  shouldn't, since the whole point of OAuth1 is that you *don't* need HTTPS.
  But whatever I guess.
*/
+ (NSURLRequest *)URLRequestForPath:(NSString *)unencodedPath_WITHOUT_Query
                      GETParameters:(NSDictionary *)unencodedParameters
                             scheme:(NSString *)scheme
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret;

/**
  We always POST with HTTPS. This is because at least half the time the user's
  data is at least somewhat private, but also because apparently some carriers
  mangle POST requests and break them. We saw this in France for example.
  READ THE DOCUMENTATION FOR GET AS IT APPLIES HERE TOO!
*/
+ (NSURLRequest *)URLRequestForPath:(NSString *)unencodedPath
                     POSTParameters:(NSDictionary *)unencodedParameters
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret;
@end


/**
  XAuth example (because you may otherwise be scratching your head):

    NSURLRequest *xauth = [TDOAuth URLRequestForPath:@"/oauth/access_token"
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

    NSURLRequest *echo = [TDOAuth URLRequestForPath:@"/1/account/verify_credentials.json"
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
*/


/**
  Suggested usage would be to make some categories for this class that
  automatically adds both secrets, both tokens and host information. This
  makes usage less cumbersome. Eg:

      [TwitterOAuth GET:@"/1/statuses/home_timeline.json"];
      [TwitterOAuth GET:@"/1/statuses/home_timeline.json" queryParameters:dictionary];

  At TweetDeck we have TDAccount classes that represent separate user logins
  for different services when instantiated.
*/


/**
  OAuth requires the UTC timestamp we send to be accurate. The user's device
  may not be, and often isn't. To work around this you should set this to the
  UTC timestamp that you get back in HTTP header from OAuth servers.
*/
extern int TDOAuthUTCTimeOffset;



@interface NSString (TweetDeck)
- (NSString*)pcen;
@end

@interface NSMutableString (TweetDeck)
- (NSMutableString *)add:(NSString *)s;
- (NSMutableString *)chomp;
@end
