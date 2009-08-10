//
//  OTRestModel.h
//  TimeTrackerOSX
//
//  Created by Jeremy Ellison on 8/8/09.
//  Copyright 2009 Objective3. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ElementParser.h"

#ifdef TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	#import <UIKit/UIKit.h>
	#define context [[[UIApplication sharedApplication] delegate] managedObjectContext]
#else
	#import <AppKit/AppKit.h>
	#define context [[[NSApplication sharedApplication] delegate] managedObjectContext]
#endif



#define kResponseUserInfoKey @"ResponseUserInfoKey"

#define kRailsToXMLDateFormatterString @"yyyy-MM-dd'T'HH:mm:ss'Z'" // 2009-08-08T17:23:59Z

@interface OTRestModel : NSManagedObject   {

}

// Subclasses Must Implement:
+ (NSDictionary*)propertyMappings;
//+ (NSString*) entityName;
//+ (NSString*) restId;
// Not Required
+ (NSDictionary*)relationshipMappings;

// finders
+ (NSArray*)allObjects;
+ (id)objectWithRestId:(NSNumber*)restId;
+ (NSArray*)collectionWithRequest:(NSFetchRequest*)request;
+ (NSFetchRequest*)request;
+ (NSEntityDescription*)entity;

+ (id)createNewObject;
- (id)updateObjectWithElement:(Element*)element;
+ (id)createNewObjectFromElement:(Element*)element;
+ (id)createOrUpdateAttributesFromXML:(Element*)XML;



@end
