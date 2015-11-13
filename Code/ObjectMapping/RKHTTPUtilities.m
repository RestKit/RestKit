//
//  RKHTTPUtilities.m
//  RestKit
//
//  Created by Blake Watters on 8/24/12.
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

#import <RestKit/ObjectMapping/RKHTTPUtilities.h>

NSUInteger RKStatusCodeRangeLength = 100;

NSRange RKStatusCodeRangeForClass(RKStatusCodeClass statusCodeClass)
{
    return NSMakeRange(statusCodeClass, RKStatusCodeRangeLength);
}

NSIndexSet *RKStatusCodeIndexSetForClass(RKStatusCodeClass statusCodeClass)
{
    return [NSIndexSet indexSetWithIndexesInRange:RKStatusCodeRangeForClass(statusCodeClass)];
}

NSIndexSet *RKCacheableStatusCodes(void)
{
    NSMutableIndexSet *cacheableStatusCodes = [NSMutableIndexSet indexSet];
    [cacheableStatusCodes addIndex:200];
    [cacheableStatusCodes addIndex:304];
    [cacheableStatusCodes addIndex:203];
    [cacheableStatusCodes addIndex:300];
    [cacheableStatusCodes addIndex:301];
    [cacheableStatusCodes addIndex:302];
    [cacheableStatusCodes addIndex:307];
    [cacheableStatusCodes addIndex:410];
    return cacheableStatusCodes;
}

BOOL RKIsSpecificRequestMethod(RKRequestMethod method)
{
    // check for a power of two
    return !(method & (method - 1));
}

NSString *RKStringFromRequestMethod(RKRequestMethod method)
{
    switch (method) {
        case RKRequestMethodGET:     return @"GET";
        case RKRequestMethodPOST:    return @"POST";
        case RKRequestMethodPUT:     return @"PUT";
        case RKRequestMethodPATCH:   return @"PATCH";
        case RKRequestMethodDELETE:  return @"DELETE";
        case RKRequestMethodHEAD:    return @"HEAD";
        case RKRequestMethodOPTIONS: return @"OPTIONS";
        default:                     break;
    }
    return nil;
}

RKRequestMethod RKRequestMethodFromString(NSString *methodName)
{
    if      ([methodName isEqualToString:@"GET"])     return RKRequestMethodGET;
    else if ([methodName isEqualToString:@"POST"])    return RKRequestMethodPOST;
    else if ([methodName isEqualToString:@"PUT"])     return RKRequestMethodPUT;
    else if ([methodName isEqualToString:@"DELETE"])  return RKRequestMethodDELETE;
    else if ([methodName isEqualToString:@"HEAD"])    return RKRequestMethodHEAD;
    else if ([methodName isEqualToString:@"PATCH"])   return RKRequestMethodPATCH;
    else if ([methodName isEqualToString:@"OPTIONS"]) return RKRequestMethodOPTIONS;
    else                                              @throw [NSException exceptionWithName:NSInvalidArgumentException
                                                                                     reason:[NSString stringWithFormat:@"The given HTTP request method name `%@` does not correspond to any known request methods.", methodName]
                                                                                   userInfo:nil];
}

// Built from http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
static NSDictionary *RKStatusCodesToNamesDictionary()
{
    static NSDictionary *statusCodesToNamesDictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        statusCodesToNamesDictionary = @{
        // 1xx (Informational)
        @(100): @"Continue",
        @(101): @"Switching Protocols",
        @(102): @"Processing",
        
        // 2xx (Success)
        @(200): @"OK",
        @(201): @"Created",
        @(202): @"Accepted",
        @(203): @"Non-Authoritative Information",
        @(204): @"No Content",
        @(205): @"Reset Content",
        @(206): @"Partial Content",
        @(207): @"Multi-Status",
        @(208): @"Already Reported",
        @(226): @"IM Used",
        
        // 3xx (Redirection)
        @(300): @"Multiple Choices",
        @(301): @"Moved Permanently",
        @(302): @"Found",
        @(303): @"See Other",
        @(304): @"Not Modified",
        @(305): @"Use Proxy",
        @(306): @"Switch Proxy",
        @(307): @"Temporary Redirect",
        @(308): @"Permanent Redirect",
        
        // 4xx (Client Error)
        @(400): @"Bad Request",
        @(401): @"Unauthorized",
        @(402): @"Payment Required",
        @(403): @"Forbidden",
        @(404): @"Not Found",
        @(405): @"Method Not Allowed",
        @(406): @"Not Acceptable",
        @(407): @"Proxy Authentication Required",
        @(408): @"Request Timeout",
        @(409): @"Conflict",
        @(410): @"Gone",
        @(411): @"Length Required",
        @(412): @"Precondition Failed",
        @(413): @"Request Entity Too Large",
        @(414): @"Request-URI Too Long",
        @(415): @"Unsupported Media Type",
        @(416): @"Requested Range Not Satisfiable",
        @(417): @"Expectation Failed",
        @(418): @"I'm a teapot",
        @(420): @"Enhance Your Calm",
        @(422): @"Unprocessable Entity",
        @(423): @"Locked",
        @(424): @"Failed Dependency",
        @(424): @"Method Failure",
        @(425): @"Unordered Collection",
        @(426): @"Upgrade Required",
        @(428): @"Precondition Required",
        @(429): @"Too Many Requests",
        @(431): @"Request Header Fields Too Large",
        @(451): @"Unavailable For Legal Reasons",
        
        // 5xx (Server Error)
        @(500): @"Internal Server Error",
        @(501): @"Not Implemented",
        @(502): @"Bad Gateway",
        @(503): @"Service Unavailable",
        @(504): @"Gateway Timeout",
        @(505): @"HTTP Version Not Supported",
        @(506): @"Variant Also Negotiates",
        @(507): @"Insufficient Storage",
        @(508): @"Loop Detected",
        @(509): @"Bandwidth Limit Exceeded",
        @(510): @"Not Extended",
        @(511): @"Network Authentication Required",
        };
    });
    return statusCodesToNamesDictionary;
}

NSString * RKStringFromStatusCode(NSInteger statusCode)
{
    return RKStatusCodesToNamesDictionary()[@(statusCode)];
}


/**
 Below is ragel source used to compile those tables. The output was polished / pretty-printed and tweaked from ragel.
 As the generated code is "hard" to debug, we store the code in http-date.r1
 
 shell% ragel -F1 http-date.rl
 shell% gcc -o http-date http-date.c
 shell% ./http-date 'Sun, 06 Nov 1994 08:49:37 GMT' 'Sunday, 06-Nov-94 08:49:37 GMT' 'Sun Nov  6 08:49:37 1994' 'Sat Dec 24 14:34:26 2037' 'Sunday, 06-Nov-94 08:49:37 GMT' 'Sun, 06 Nov 1994 08:49:37 GMT'
 */
static const char _httpDate_trans_keys[] = {
    0,   0,  70,  87, 114, 114, 105, 105,  32, 100,  65,  83, 112, 117, 114, 114,  32,
    32,  32,  57,  48,  57,  32,  32,  48,  57,  48,  57,  58,  58,  48,  57,  48,  57,
    58,  58,  48,  57,  48,  57,  32,  32,  48,  57,  48,  57,  48,  57,  48,  57, 103,
    103, 101, 101,  99,  99, 101, 101,  98,  98,  97, 117, 110, 110, 108, 110,  97,  97,
    114, 121, 111, 111, 118, 118,  99,  99, 116, 116, 101, 101, 112, 112,  32,  32,  48,
    57,  48,  57,  32,  32,  65,  83, 112, 117, 114, 114,  32,  32,  48,  57,  48,  57,
    48,  57,  48,  57,  32,  32,  48,  57,  48,  57,  58,  58,  48,  57,  48,  57,  58,
    58,  48,  57,  48,  57,  32,  32,  71,  71,  77,  77,  84,  84, 103, 103, 101, 101,
    99,  99, 101, 101,  98,  98,  97, 117, 110, 110, 108, 110,  97,  97, 114, 121, 111,
    111, 118, 118,  99,  99, 116, 116, 101, 101, 112, 112,  97,  97, 121, 121,  44,  44,
    32,  32,  48,  57,  48,  57,  45,  45,  65,  83, 112, 117, 114, 114,  45,  45,  48,
    57,  48,  57,  32,  32,  48,  57,  48,  57,  58,  58,  48,  57,  48,  57,  58,  58,
    48,  57,  48,  57,  32,  32,  71,  71,  77,  77,  84,  84, 103, 103, 101, 101,  99,
    99, 101, 101,  98,  98,  97, 117, 110, 110, 108, 110,  97,  97, 114, 121, 111, 111,
    118, 118,  99,  99, 116, 116, 101, 101, 112, 112, 111, 111, 110, 110,  97, 117, 116,
    116,  32, 117, 114, 114, 100, 100, 104, 117, 117, 117,  32, 114, 115, 115, 101, 101,
    32, 115, 101, 101, 100, 100,  32, 110, 101, 101,   0,   0,   0,   0,   0,   0,   0
};

static const char _httpDate_key_spans[] = {
    0, 18,  1,  1, 69, 19,  6,  1,  1, 26, 10,  1, 10, 10,  1, 10, 10,
    1, 10, 10,  1, 10, 10, 10, 10,  1,  1,  1,  1,  1, 21,  1,  3,  1,
    8,  1,  1,  1,  1,  1,  1,  1, 10, 10,  1, 19,  6,  1,  1, 10, 10,
    10, 10,  1, 10, 10,  1, 10, 10,  1, 10, 10,  1,  1,  1,  1,  1,  1,
    1,  1,  1, 21,  1,  3,  1,  8,  1,  1,  1,  1,  1,  1,  1,  1,  1,
    1, 10, 10,  1, 19,  6,  1,  1, 10, 10,  1, 10, 10,  1, 10, 10,  1,
    10, 10,  1,  1,  1,  1,  1,  1,  1,  1,  1, 21,  1,  3,  1,  8,  1,
    1,  1,  1,  1,  1,  1,  1, 21,  1, 86,  1,  1, 14,  1, 83,  1,  1,
    84,  1,  1, 79,  1,  0,  0,  0
};

static const short _httpDate_index_offsets[] = {
    0,    0,   19,   21,   23,   93,  113,  120,  122,  124,  151,  162,  164,  175,  186,  188,  199,
    210,  212,  223,  234,  236,  247,  258,  269,  280,  282,  284,  286,  288,  290,  312,  314,  318,
    320,  329,  331,  333,  335,  337,  339,  341,  343,  354,  365,  367,  387,  394,  396,  398,  409,
    420,  431,  442,  444,  455,  466,  468,  479,  490,  492,  503,  514,  516,  518,  520,  522,  524,
    526,  528,  530,  532,  554,  556,  560,  562,  571,  573,  575,  577,  579,  581,  583,  585,  587,
    589,  591,  602,  613,  615,  635,  642,  644,  646,  657,  668,  670,  681,  692,  694,  705,  716,
    718,  729,  740,  742,  744,  746,  748,  750,  752,  754,  756,  758,  780,  782,  786,  788,  797,
    799,  801,  803,  805,  807,  809,  811,  813,  835,  837,  924,  926,  928,  943,  945, 1029, 1031,
    1033, 1118, 1120, 1122, 1202, 1204, 1205, 1206
};

static const unsigned char _httpDate_indicies[] = {
    0,   1,   1,   1,   1,   1,   1,   2,   1,   1,   1,   1,   1,   3,   4,   1,   1,
    5,   1,   6,   1,   7,   1,   8,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   9,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,  10,   1,  11,   1,   1,  12,   1,  13,   1,   1,   1,
    14,   1,   1,  15,  16,  17,   1,   1,   1,  18,   1,  19,   1,   1,   1,   1,  20,
    1,  21,   1,  22,   1,  23,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,  24,  24,  24,  24,  24,  24,  24,  24,  24,  24,   1,  25,  25,
    25,  25,  25,  25,  25,  25,  25,  25,   1,  26,   1,  27,  27,  27,  27,  27,  27,
    27,  27,  27,  27,   1,  28,  28,  28,  28,  28,  28,  28,  28,  28,  28,   1,  29,
    1,  30,  30,  30,  30,  30,  30,  30,  30,  30,  30,   1,  31,  31,  31,  31,  31,
    31,  31,  31,  31,  31,   1,  32,   1,  33,  33,  33,  33,  33,  33,  33,  33,  33,
    33,   1,  34,  34,  34,  34,  34,  34,  34,  34,  34,  34,   1,  35,   1,  36,  36,
    36,  36,  36,  36,  36,  36,  36,  36,   1,  37,  37,  37,  37,  37,  37,  37,  37,
    37,  37,   1,  38,  38,  38,  38,  38,  38,  38,  38,  38,  38,   1,  39,  39,  39,
    39,  39,  39,  39,  39,  39,  39,   1,  40,   1,  41,   1,  42,   1,  43,   1,  44,
    1,  45,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,  46,   1,  47,   1,  48,   1,  49,   1,  50,   1,  51,   1,   1,
    1,   1,   1,   1,  52,   1,  53,   1,  54,   1,  55,   1,  56,   1,  57,   1,  58,
    1,  59,   1,  60,  60,  60,  60,  60,  60,  60,  60,  60,  60,   1,  61,  61,  61,
    61,  61,  61,  61,  61,  61,  61,   1,  62,   1,  63,   1,   1,  64,   1,  65,   1,
    1,   1,  66,   1,   1,  67,  68,  69,   1,   1,   1,  70,   1,  71,   1,   1,   1,
    1,  72,   1,  73,   1,  74,   1,  75,  75,  75,  75,  75,  75,  75,  75,  75,  75,
    1,  76,  76,  76,  76,  76,  76,  76,  76,  76,  76,   1,  77,  77,  77,  77,  77,
    77,  77,  77,  77,  77,   1,  78,  78,  78,  78,  78,  78,  78,  78,  78,  78,   1,
    79,   1,  80,  80,  80,  80,  80,  80,  80,  80,  80,  80,   1,  81,  81,  81,  81,
    81,  81,  81,  81,  81,  81,   1,  82,   1,  83,  83,  83,  83,  83,  83,  83,  83,
    83,  83,   1,  84,  84,  84,  84,  84,  84,  84,  84,  84,  84,   1,  85,   1,  86,
    86,  86,  86,  86,  86,  86,  86,  86,  86,   1,  87,  87,  87,  87,  87,  87,  87,
    87,  87,  87,   1,  88,   1,  89,   1,  90,   1,  91,   1,  92,   1,  93,   1,  94,
    1,  95,   1,  96,   1,  97,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,  98,   1,  99,   1, 100,   1, 101,   1, 102,
    1, 103,   1,   1,   1,   1,   1,   1, 104,   1, 105,   1, 106,   1, 107,   1, 108,
    1, 109,   1, 110,   1, 111,   1, 112,   1, 113,   1, 114,   1, 115, 115, 115, 115,
    115, 115, 115, 115, 115, 115,   1, 116, 116, 116, 116, 116, 116, 116, 116, 116, 116,
    1, 117,   1, 118,   1,   1, 119,   1, 120,   1,   1,   1, 121,   1,   1, 122, 123,
    124,   1,   1,   1, 125,   1, 126,   1,   1,   1,   1, 127,   1, 128,   1, 129,   1,
    130, 130, 130, 130, 130, 130, 130, 130, 130, 130,   1, 131, 131, 131, 131, 131, 131,
    131, 131, 131, 131,   1, 132,   1, 133, 133, 133, 133, 133, 133, 133, 133, 133, 133,
    1, 134, 134, 134, 134, 134, 134, 134, 134, 134, 134,   1, 135,   1, 136, 136, 136,
    136, 136, 136, 136, 136, 136, 136,   1, 137, 137, 137, 137, 137, 137, 137, 137, 137,
    137,   1, 138,   1, 139, 139, 139, 139, 139, 139, 139, 139, 139, 139,   1, 140, 140,
    140, 140, 140, 140, 140, 140, 140, 140,   1, 141,   1, 142,   1, 143,   1, 144,   1,
    145,   1, 146,   1, 147,   1, 148,   1, 149,   1, 150,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1, 151,   1, 152,   1,
    153,   1, 154,   1, 155,   1, 156,   1,   1,   1,   1,   1,   1, 157,   1, 158,   1,
    159,   1, 160,   1, 161,   1, 162,   1, 163,   1, 164,   1,   7,   1, 165,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    164,   1, 166,   1,   8,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   9,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1, 167,   1, 168,   1,  10,   1, 169,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1, 170,   1, 171,   1,   8,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   9,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1, 172,   1, 168,   1, 173,   1,   8,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   9,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1, 168,   1, 174,   1, 175,   1,
    8,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   9,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,   1,
    1,   1,   1,   1,   1,   1,   1,   1,   1,   1, 176,   1, 172,   1,   1,   1,   1,
    0
};

static const unsigned char _httpDate_trans_targs[] = {
    2,   0, 124, 126, 131, 137,   3,   4,   5,  41,  82,   6,  26,  28,  30,  33,  35,
    37,  39,   7,  25,   8,   9,  10,  10,  11,  12,  13,  14,  15,  16,  17,  18,  19,
    20,  21,  22,  23,  24, 141,   8,  27,   8,  29,   8,  31,  32,   8,   8,   8,  34,
    8,   8,  36,   8,  38,   8,  40,   8,  42,  43,  44,  45,  46,  67,  69,  71,  74,
    76,  78,  80,  47,  66,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,
    60,  61,  62,  63,  64,  65, 142,  48,  68,  48,  70,  48,  72,  73,  48,  48,  48,
    75,  48,  48,  77,  48,  79,  48,  81,  48,  83,  84,  85,  86,  87,  88,  89,  90,
    109, 111, 113, 116, 118, 120, 122,  91, 108,  92,  93,  94,  95,  96,  97,  98,  99,
    100, 101, 102, 103, 104, 105, 106, 107, 143,  92, 110,  92, 112,  92, 114, 115,  92,
    92,  92, 117,  92,  92, 119,  92, 121,  92, 123,  92, 125, 127, 128, 129, 130, 132,
    135, 133, 134, 136, 138, 139, 140
};

static const char _httpDate_trans_actions[] = {
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  1,  0,  0,  2,  2,  0,  3,  3,  0,  4,  4,  0,  5,
    5,  0,  6,  6,  6,  6,  7,  0,  8,  0,  9,  0,  0, 10, 11, 12,  0,
    13, 14,  0, 15,  0, 16,  0, 17,  0,  2,  2,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  1,  0,  6,  6,  6,  6,  0,  3,  3,  0,  4,  4,
    0,  5,  5,  0,  0,  0,  0,  7,  0,  8,  0,  9,  0,  0, 10, 11, 12,
    0, 13, 14,  0, 15,  0, 16,  0, 17,  0,  0,  0,  0,  2,  2,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  0,  6, 18,  0,  3,  3,  0,
    4,  4,  0,  5,  5,  0,  0,  0,  0,  7,  0,  8,  0,  9,  0,  0, 10,
    11, 12,  0, 13, 14,  0, 15,  0, 16,  0, 17,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0
};

static const char _httpDate_eof_actions[] = {
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0, 19, 20, 21
};

static NSDate *_parseHTTPDate(const char *buf, size_t bufLen) {
    const char *p = buf, *pe = p + bufLen, *eof = pe;
    int parsed = 0, cs = 1;
    NSDate *date = NULL;
    
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && (__IPHONE_OS_VERSION_MAX_ALLOWED < 70000)) || \
(defined(MAC_OS_X_VERSION_MAX_ALLOWED) && (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_9))
    CFGregorianDate gdate;
    memset(&gdate, 0, sizeof(CFGregorianDate));
#else
    NSDateComponents *gdate = [[NSDateComponents alloc] init];
    gdate.year = 0;
    gdate.month = 0;
    gdate.day = 0;
    gdate.hour = 0;
    gdate.minute = 0;
    gdate.second = 0;
#endif
    
    {
        int _slen, _trans;
        const char *_keys;
        const unsigned char *_inds;
        if(p  == pe) { goto _test_eof; }
    _resume:
        _keys  = _httpDate_trans_keys + (cs << 1);
        _inds  = _httpDate_indicies   + _httpDate_index_offsets[cs];
        _slen  = _httpDate_key_spans[cs];
        _trans = _inds[(_slen > 0) && (_keys[0] <= (*p)) && ((*p) <= _keys[1]) ? (*p) - _keys[0] : _slen];
        cs     = _httpDate_trans_targs[_trans];
        
        if(_httpDate_trans_actions[_trans] == 0) { goto _again; }
        
        switch(_httpDate_trans_actions[_trans]) {
            case 6:  gdate.year   = gdate.year * 10 + ((*p) - '0');                     break;
            case 18: gdate.year   = gdate.year * 10 + ((*p) - '0'); gdate.year += 1900; break;
            case 10: gdate.month  =  1; break;
            case 9:  gdate.month  =  2; break;
            case 13: gdate.month  =  3; break;
            case 1:  gdate.month  =  4; break;
            case 14: gdate.month  =  5; break;
            case 12: gdate.month  =  6; break;
            case 11: gdate.month  =  7; break;
            case 7:  gdate.month  =  8; break;
            case 17: gdate.month  =  9; break;
            case 16: gdate.month  = 10; break;
            case 15: gdate.month  = 11; break;
            case 8:  gdate.month  = 12; break;
            case 2:  gdate.day    = gdate.day    * 10   + ((*p) - '0'); break;
            case 3:  gdate.hour   = gdate.hour   * 10   + ((*p) - '0'); break;
            case 4:  gdate.minute = gdate.minute * 10   + ((*p) - '0'); break;
            case 5:  gdate.second = gdate.second * 10.0 + ((*p) - '0'); break;
        }
        
    _again:
        if(  cs ==  0) { goto _out;    }
        if(++p  != pe) { goto _resume; }
    _test_eof: {}
        if(p == eof) {
            switch(_httpDate_eof_actions[cs]) {
                case 19: parsed = 1; break;
                case 20: parsed = 1; break;
                case 21: parsed = 1; break;
            }
        }
        
    _out: {}
    }
    
    static dispatch_once_t onceToken;
    
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && (__IPHONE_OS_VERSION_MAX_ALLOWED < 70000)) || \
(defined(MAC_OS_X_VERSION_MAX_ALLOWED) && (MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_9))
    static CFTimeZoneRef gmtTimeZone;
    dispatch_once(&onceToken, ^{
        gmtTimeZone = CFTimeZoneCreateWithTimeIntervalFromGMT(NULL, 0.0);
    });
    
    if (parsed == 1) {
        date = [NSDate dateWithTimeIntervalSinceReferenceDate:CFGregorianDateGetAbsoluteTime(gdate, gmtTimeZone)];
    }
#else
    static NSCalendar *gregorian;
    dispatch_once(&onceToken, ^{
        gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        gregorian.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });
    
    if (parsed == 1) {
        date = [gregorian dateFromComponents:gdate];
    }
#endif
    
    return(date);
}

/*
 * Parse HTTP Date: http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3.1
 */
NSDate * RKDateFromHTTPDateString(NSString *httpDate)
{
    char stringBuffer[256];
    size_t stringLength = (size_t)CFStringGetLength((__bridge CFStringRef)httpDate);
    const char *cStringPtr = (const char *)CFStringGetCStringPtr((__bridge CFStringRef)httpDate, kCFStringEncodingMacRoman);
    if(cStringPtr == NULL) {
        CFIndex usedBytes = 0L, convertedCount = 0L;
        convertedCount = CFStringGetBytes((__bridge CFStringRef)httpDate, CFRangeMake(0L, (CFIndex)stringLength), kCFStringEncodingUTF8, '?', NO, (UInt8 *)stringBuffer, sizeof(stringBuffer) - 1L, &usedBytes);
        if(((size_t)convertedCount != stringLength) || (usedBytes < 0L)) { return(NULL); }
        stringBuffer[usedBytes] = '\0';
        cStringPtr = (const char *)stringBuffer;
    }
    return(_parseHTTPDate(cStringPtr, stringLength));
}

static float const kRKURLCacheLastModFraction = 0.1f; // 10% since Last-Modified suggested by RFC2616 section 13.2.4
static float const kRKURLCacheDefault = 3600.0f; // Default cache expiration delay if none defined (1 hour)

/*
 * This method tries to determine the expiration date based on a response headers dictionary.
 */
NSDate * RKHTTPCacheExpirationDateFromHeadersWithStatusCode(NSDictionary *headers, NSInteger statusCode)
{
    if (statusCode != 200 && statusCode != 203 && statusCode != 300 && statusCode != 301 && statusCode != 302 && statusCode != 307 && statusCode != 410) {
        // Uncacheable response status code
        return nil;
    }
    
    // Check Pragma: no-cache
    NSString *pragma = headers[@"Pragma"];
    if (pragma && [pragma isEqualToString:@"no-cache"]) {
        // Uncacheable response
        return nil;
    }
    
    // Define "now" based on the request
    NSString *date = headers[@"Date"];
    // If no Date: header, define now from local clock
    NSDate *now = date ? RKDateFromHTTPDateString(date) : [NSDate date];
    
    // Look at info from the Cache-Control: max-age=n header
    NSString *cacheControl = [headers[@"Cache-Control"] lowercaseString];
    if (cacheControl)
    {
        NSRange foundRange = [cacheControl rangeOfString:@"no-store"];
        if (foundRange.length > 0) {
            // If no-store, the content cannot be cached at all
            // See http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9.2
            return nil;
        }
        
        foundRange = [cacheControl rangeOfString:@"no-cache"];
        if (foundRange.length > 0) {
            // If no-cache, we must revalidate with the origin server
            // See http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9.1
            return nil;
        }
        
        NSInteger maxAge;
        foundRange = [cacheControl rangeOfString:@"max-age"];
        if (foundRange.length > 0) {
            NSScanner *cacheControlScanner = [NSScanner scannerWithString:cacheControl];
            [cacheControlScanner setScanLocation:foundRange.location + foundRange.length];
            [cacheControlScanner scanString:@"=" intoString:nil];
            if ([cacheControlScanner scanInteger:&maxAge]) {
            	if(maxAge > 0)
                {
                    const NSInteger age = ((NSString *)headers[@"Age"]).integerValue;
                    if(age > 0)
                    	return [[NSDate alloc] initWithTimeIntervalSinceNow:(maxAge - age)];
                    else
                    	return [[NSDate alloc] initWithTimeInterval:maxAge sinceDate:now];
                }
                else
                	return nil;
            }
        }
    }
    
    // If not Cache-Control found, look at the Expires header
    NSString *expires = headers[@"Expires"];
    if (expires) {
        NSTimeInterval expirationInterval = 0;
        NSDate *expirationDate = RKDateFromHTTPDateString(expires);
        if (expirationDate) {
            expirationInterval = [expirationDate timeIntervalSinceDate:now];
        }
        if (expirationInterval > 0) {
            // Convert remote expiration date to local expiration date
            return [NSDate dateWithTimeIntervalSinceNow:expirationInterval];
        }
        else {
            // If the Expires header can't be parsed or is expired, do not cache
            return nil;
        }
    }
    
    if (statusCode == 302 || statusCode == 307) {
        // If not explict cache control defined, do not cache those status
        return nil;
    }
    
    // If no cache control defined, try some heristic to determine an expiration date
    NSString *lastModified = headers[@"Last-Modified"];
    if (lastModified) {
        NSTimeInterval age = 0;
        NSDate *lastModifiedDate = RKDateFromHTTPDateString(lastModified);
        if (lastModifiedDate) {
            // Define the age of the document by comparing the Date header with the Last-Modified header
            age = [now timeIntervalSinceDate:lastModifiedDate];
        }
        return age > 0 ? [NSDate dateWithTimeIntervalSinceNow:(age * kRKURLCacheLastModFraction)] : nil;
    }
    
    // If nothing permitted to define the cache expiration delay nor to restrict its cacheability, use a default cache expiration delay
    return [[NSDate alloc] initWithTimeInterval:kRKURLCacheDefault sinceDate:now];
}

BOOL RKURLIsRelativeToURL(NSURL *URL, NSURL *baseURL)
{
    return [[URL absoluteString] hasPrefix:[baseURL absoluteString]];
}

NSString *RKPathAndQueryStringFromURLRelativeToURL(NSURL *URL, NSURL *baseURL)
{
    if (baseURL) {
        if (! RKURLIsRelativeToURL(URL, baseURL)) return nil;
        return [[URL absoluteString] substringFromIndex:[[baseURL absoluteString] length]];
    } else {
        // NOTE: [URL relativeString] would return the same value as `absoluteString` if URL is not relative to a baseURL
        NSString *query = [URL query];
        NSString *pathWithPrevervedTrailingSlash = [CFBridgingRelease(CFURLCopyPath((CFURLRef)URL)) stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        return (query && [query length]) ? [NSString stringWithFormat:@"%@?%@", pathWithPrevervedTrailingSlash, query] : pathWithPrevervedTrailingSlash;
    }
}

NSIndexSet *RKStatusCodesOfResponsesWithOptionalBodies()
{
    NSMutableIndexSet *statusCodes = [NSMutableIndexSet indexSet];
    [statusCodes addIndex:201];
    [statusCodes addIndex:202];
    [statusCodes addIndex:204];
    [statusCodes addIndex:205];
    [statusCodes addIndex:304];
    return statusCodes;
}
