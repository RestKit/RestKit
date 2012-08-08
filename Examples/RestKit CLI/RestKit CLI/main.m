//
//  main.m
//  RestKit CLI
//
//  Created by Blake Watters on 10/15/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

int main (int argc, const char *argv[])
{

    @autoreleasepool {
        RKLogConfigureByName("App", RKLogLevelTrace);

        // Validate arguments
        if (argc < 2) {
            printf("usage: %s path/to/file [keyPath]\n", argv[0]);
            printf("Parses the specified file and outputs the payload.\n"
                   "If keyPath is provided it will be evaluated against the payload and the result printed.\n");
            return 0;
        }

        NSString *filePathOrURL = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
        NSURL *URL = nil;
        NSString *keyPath = nil;

        if ([filePathOrURL rangeOfString:@"://"].length == 0) {
            // Local file
            URL = [NSURL fileURLWithPath:filePathOrURL];
        } else {
            // Web URL
            URL = [NSURL URLWithString:filePathOrURL];
        }
        if (argc == 3) keyPath = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];

        NSError *error = nil;
        NSString *payload = [NSString stringWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
        if (!payload) {
            RKLogError(@"Failed to read file at path %@: %@", URL, error);
            return 0;
        }

        NSString *MIMEType = [[URL absoluteString] MIMETypeForPathExtension];
        RKLogInfo(@"Parsing %@ using MIME Type: %@", URL, MIMEType);
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:MIMEType];
        id parsedData = [parser objectFromString:payload error:&error];
        if (!parsedData) {
            RKLogError(@"Failed to parse file: %@", error);
            RKLogError(@"Payload => %@", payload);
            return 0;
        }
        RKLogInfo(@"Parsed data => %@", parsedData);
        if (keyPath) RKLogInfo(@"valueForKeyPath:@\"%@\" => %@", keyPath, [parsedData valueForKeyPath:keyPath]);
    }

    return 0;
}
