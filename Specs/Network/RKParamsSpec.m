//
//  RKParamsSpec.m
//  RestKit
//
//  Created by Blake Watters on 6/30/11.
//  Copyright 2011 Two Toasters
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

#import "RKSpecEnvironment.h"
#import "RKParams.h"
#import "RKRequest.h"

@interface RKParamsSpec : RKSpec

@end

@implementation RKParamsSpec

- (void)testShouldNotOverReleaseTheParams {
    NSDictionary* dictionary = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
    RKParams* params = [[RKParams alloc] initWithDictionary:dictionary];
    NSURL* URL = [NSURL URLWithString:[RKSpecGetBaseURL() stringByAppendingFormat:@"/echo_params"]];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.method = RKRequestMethodPOST;
    request.params = params;
    request.delegate = responseLoader;
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    [request release];
}

- (void)testShouldUploadFilesViaRKParams {
    RKClient* client = RKSpecNewClient();
    RKParams* params = [RKParams params];
    [params setValue:@"one" forParam:@"value"];
    [params setValue:@"two" forParam:@"value"];
    [params setValue:@"three" forParam:@"value"];
    [params setValue:@"four" forParam:@"value"];
    NSBundle *testBundle = [NSBundle bundleWithIdentifier:@"org.restkit.unit-tests"];
    NSString *imagePath = [testBundle pathForResource:@"blake" ofType:@"png"];
    NSData *data = [NSData dataWithContentsOfFile:imagePath];
    [params setData:data MIMEType:@"image/png" forParam:@"file"];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];    
    [client post:@"/upload" params:params delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatInteger(responseLoader.response.statusCode, is(equalToInt(200)));
}

- (void)testShouldUploadFilesViaRKParamsWithMixedTypes {
    NSNumber* idUsuari = [NSNumber numberWithInt:1234]; 
    NSArray* userList = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
    NSNumber* idTema = [NSNumber numberWithInt:1234]; 
    NSString* titulo = @"whatever";
    NSString* texto = @"more text";
    NSBundle *testBundle = [NSBundle bundleWithIdentifier:@"org.restkit.unit-tests"];
    NSString *imagePath = [testBundle pathForResource:@"blake" ofType:@"png"];
    NSData *data = [NSData dataWithContentsOfFile:imagePath];
    NSNumber* cel = [NSNumber numberWithFloat:1.232442];
    NSNumber* lon = [NSNumber numberWithFloat:18231.232442];;
    NSNumber* lat = [NSNumber numberWithFloat:13213123.232442];;
    
    RKParams* params = [RKParams params];
    
    // Set values
    [params setValue:idUsuari forParam:@"idUsuariPropietari"];
    [params setValue:userList forParam:@"telUser"];
    [params setValue:idTema forParam:@"idTema"];
    [params setValue:titulo forParam:@"titulo"];
    [params setValue:texto forParam:@"texto"];
    
    [params setData:data MIMEType:@"image/png" forParam:@"file"];
    
    [params setValue:cel forParam:@"cel"];
    [params setValue:lon forParam:@"lon"];
    [params setValue:lat forParam:@"lat"];
    
    RKClient* client = RKSpecNewClient();
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];    
    [client post:@"/upload" params:params delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatInteger(responseLoader.response.statusCode, is(equalToInt(200)));
}

- (void)testShouldCalculateAnMD5ForTheParams {
    NSDictionary *values = [NSDictionary dictionaryWithObjectsAndKeys:@"foo", @"bar", @"this", @"that", nil];
    RKParams *params = [RKParams paramsWithDictionary:values];
    NSString *MD5 = [params MD5];
    assertThat(MD5, is(equalTo(@"da7d80084b86aa5022b434e3bf084caf")));
}

@end
