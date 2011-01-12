//
//  RKURL.h
//  RestKit
//
//  Created by Jeff Arena on 10/18/10.
//
//


@interface RKURL : NSURL {
	NSString* _baseURLString;
	NSString* _resourcePath;
}

@property (nonatomic, readonly) NSString* baseURLString;
@property (nonatomic, readonly) NSString* resourcePath;

- (id)initWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath;
+ (RKURL*)URLWithBaseURLString:(NSString*)baseURLString resourcePath:(NSString*)resourcePath;

@end
