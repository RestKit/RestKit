//
//  RKParamsDataAttachment.h
//  RestKit
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKParamsAttachment.h"

@interface RKParamsDataAttachment : RKParamsAttachment {
	NSData* _data;
}

/**
 * The data being attached to the MIME stream
 */
@property (nonatomic, retain) NSData* data;

@end
