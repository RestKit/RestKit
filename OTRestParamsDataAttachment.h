//
//  OTRestParamsDataAttachment.h
//  OTRestFramework
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "OTRestParamsAttachment.h"

@interface OTRestParamsDataAttachment : OTRestParamsAttachment {
	NSData* _data;
}

/**
 * The data being attached to the MIME stream
 */
@property (nonatomic, retain) NSData* data;

@end
