//
//  RKParamsFileAttachment.h
//  RestKit
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKParamsAttachment.h"

@interface RKParamsFileAttachment : RKParamsAttachment {
	NSString* _filePath;
}

/**
 * The path to this file attachment on disk
 */
@property (nonatomic, retain) NSString* filePath;

@end
