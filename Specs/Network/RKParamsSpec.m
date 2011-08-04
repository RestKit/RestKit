//
//  RKParamsSpec.m
//  RestKit
//
//  Created by Blake Watters on 6/30/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKParams.h"
#import "RKRequest.h"

@interface RKParamsSpec : RKSpec

@end

@implementation RKParamsSpec

- (void)itShouldNotOverReleaseTheParams {
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

- (void)itShouldUploadFilesViaRKParams {
    RKClient* client = RKSpecNewClient();
    RKParams* params = [RKParams params];
    [params setValue:@"one" forParam:@"value"];
    [params setValue:@"two" forParam:@"value"];
    [params setValue:@"three" forParam:@"value"];
    [params setValue:@"four" forParam:@"value"];
    UIImage* image = [UIImage imageNamed:@"blake.png"];
    [params setData:UIImagePNGRepresentation(image) MIMEType:@"image/png" forParam:@"file"];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];    
    [client post:@"/upload" params:params delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatInt(responseLoader.response.statusCode, is(equalToInt(200)));
}

- (void)itShouldUploadFilesViaRKParamsWithMixedTypes {
    NSNumber* idUsuari = [NSNumber numberWithInt:1234]; 
    NSArray* userList = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
    NSNumber* idTema = [NSNumber numberWithInt:1234]; 
    NSString* titulo = @"whatever";
    NSString* texto = @"more text";
    NSData* imagen = UIImageJPEGRepresentation([UIImage imageNamed:@"blake.png"], 1.0);
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
    
    [params setData:imagen MIMEType:@"image/jpeg" forParam:@"file"];
    
    [params setValue:cel forParam:@"cel"];
    [params setValue:lon forParam:@"lon"];
    [params setValue:lat forParam:@"lat"];
    
    RKClient* client = RKSpecNewClient();
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];    
    [client post:@"/upload" params:params delegate:responseLoader];
    [responseLoader waitForResponse];
    assertThatInt(responseLoader.response.statusCode, is(equalToInt(200)));
}

@end
