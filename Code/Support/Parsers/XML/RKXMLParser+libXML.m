//
//  RKXMLParser.mm
//
//  Created by Jeremy Ellison on 2011-02-28.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RKXMLParser.h"
//#import <libxml/parser.h>
#import <libxml2/libxml/parser.h>

@interface RKXMLParser (Private)
- (NSDictionary*)parse:(NSString*)xml;
@end

@implementation RKXMLParser

+ (NSDictionary*)parse:(NSString*)xml {
    return [[[self new] autorelease] parse:xml];
}

- (id)parseNode:(xmlNode*)node {
    NSMutableArray* nodes = [NSMutableArray array];
    NSMutableDictionary* attrs = [NSMutableDictionary dictionary];
    
    xmlNode* currentNode = NULL;
    for (currentNode = node; currentNode; currentNode = currentNode->next) {
        if (currentNode->type == XML_ELEMENT_NODE) {
            NSString* nodeName = [NSString stringWithCString:(char*)currentNode->name encoding:NSUTF8StringEncoding];
            id val = [self parseNode:currentNode->children];
            if ([val isKindOfClass:[NSString class]]) {
                [attrs setValue:val forKey:nodeName];
                // Only add attributes to nodes if there actually is one.
                if (![nodes containsObject:attrs]) {
                    [nodes addObject:attrs];
                }
            } else {
                NSDictionary* elem = [NSDictionary dictionaryWithObject:val forKey:nodeName];
                [nodes addObject:elem];
            }
            xmlElement* element = (xmlElement*)currentNode;
            xmlAttribute* currentAttribute = NULL;
            for (currentAttribute = (xmlAttribute*)element->attributes; currentAttribute; currentAttribute = (xmlAttribute*)currentAttribute->next) {
                NSString* name = [NSString stringWithCString:(char*)currentAttribute->name encoding:NSUTF8StringEncoding];
                NSString* val = [NSString stringWithCString:(char*)xmlNodeGetContent((xmlNode*)currentAttribute) encoding:NSUTF8StringEncoding];
                [attrs setValue:val forKey:name];
                // Only add attributes to nodes if there actually is one.
                if (![nodes containsObject:attrs]) {
                    [nodes addObject:attrs];
                }
            }
        } else if (currentNode->type == XML_TEXT_NODE) {
            xmlChar* str = xmlNodeGetContent(currentNode);
            NSString* part = [NSString stringWithCString:(const char*)str encoding:NSUTF8StringEncoding];
            if ([[part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
                [nodes addObject:part];
            }
        }
    }
    if ([nodes count] == 1) {
        return [nodes objectAtIndex:0];
    }
    if ([nodes count] == 0) {
        return @"";
    }
    if ([nodes containsObject:attrs]) {
        // We have both attributes and children. merge everything together.
        NSMutableDictionary* results = [NSMutableDictionary dictionary];
        for (NSDictionary* dict in nodes) {
            [results addEntriesFromDictionary:dict];
        }
        return results;
    }
    return nodes;
}

- (NSDictionary*)parse:(NSString*)xml {
    xmlParserCtxtPtr ctxt; /* the parser context */
    xmlDocPtr doc; /* the resulting document tree */
    id result = nil;;

    /* create a parser context */
    ctxt = xmlNewParserCtxt();
    if (ctxt == NULL) {
        fprintf(stderr, "Failed to allocate parser context\n");
        return nil;
    }
    /* Parse the string. */
    const char* buffer = [xml cStringUsingEncoding:NSUTF8StringEncoding];
    doc = xmlParseMemory(buffer, strlen(buffer));
    
    /* check if parsing suceeded */
    if (doc == NULL) {
        fprintf(stderr, "Failed to parse\n");
    } else {
	    /* check if validation suceeded */
        if (ctxt->valid == 0) {
	        fprintf(stderr, "Failed to validate\n");
        }
        
        /* Parse Doc into Dict */
        result = [self parseNode:doc->xmlRootNode];
        
	    /* free up the resulting document */
	    xmlFreeDoc(doc);
    }
    /* free up the parser context */
    xmlFreeParserCtxt(ctxt);
    return result;
}

- (id)objectFromString:(NSString*)string {
    return [self parse:string];
}

- (NSString*)stringFromObject:(id)object {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
