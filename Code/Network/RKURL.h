//
//  RKURL.h
//  RestKit
//
//  Created by Jeff Arena on 10/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

@interface RKURL : NSURL {
	NSString* _baseURLString;
	NSString* _resourcePath;
	NSDictionary* _queryParams;
}

@property (nonatomic, readonly) NSString* baseURLString;
@property (nonatomic, readonly) NSString* resourcePath;
@property (nonatomic, readonly) NSDictionary* queryParams;

- (id)initWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath;
- (id)initWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath queryParams:(NSDictionary*)queryParams;
+ (RKURL*)URLWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath;
+ (RKURL*)URLWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath queryParams:(NSDictionary*)queryParams;

@end
