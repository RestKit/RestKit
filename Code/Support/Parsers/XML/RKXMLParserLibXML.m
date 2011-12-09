//
//  RKXMLParserLibXML.m
//
//  Created by Jeremy Ellison on 2011-02-28.
//  Copyright 2011 RestKit
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

#import <libxml2/libxml/parser.h>
#import "RKXMLParserLibXML.h"

@implementation RKXMLParserLibXML

- (id)parseNode:(xmlNode*)node {
    NSMutableArray* nodes = [NSMutableArray array];
    NSMutableDictionary* attrs = [NSMutableDictionary dictionary];
    
    xmlNode* currentNode = NULL;
    for (currentNode = node; currentNode; currentNode = currentNode->next) {
        if (currentNode->type == XML_ELEMENT_NODE) {
            NSString* nodeName = [NSString stringWithCString:(char*)currentNode->name encoding:NSUTF8StringEncoding];
            id val = [self parseNode:currentNode->children];
            if ([val isKindOfClass:[NSString class]]) {
                id oldVal = [attrs valueForKey:nodeName];
                if (nil == oldVal) {
                    // Assume that empty strings are irrelevant and go for an attribute-collection instead
                    if ([val length] == 0) {
                        val = [NSMutableDictionary dictionary];
                        NSMutableDictionary* elem = [NSMutableDictionary dictionaryWithObject:val forKey:nodeName];
                        [nodes addObject:elem];
                    } else {
                        [attrs setValue:val forKey:nodeName];
                    }
                } else if ([oldVal isKindOfClass:[NSMutableArray class]]) {
                    [oldVal addObject:val];
                } else {
                    NSMutableArray* array = [NSMutableArray arrayWithObjects:oldVal, val, nil];
                    [attrs setValue:array forKey:nodeName];
                }
                
                // Only add attributes to nodes if there actually is one.
                if (![nodes containsObject:attrs]) {
                    [nodes addObject:attrs];
                }
            } else {
                NSMutableDictionary* elem = [NSMutableDictionary dictionaryWithObject:val forKey:nodeName];
                [nodes addObject:elem];
            }
            xmlElement* element = (xmlElement*)currentNode;
            xmlAttribute* currentAttribute = NULL;
            for (currentAttribute = (xmlAttribute*)element->attributes; currentAttribute; currentAttribute = (xmlAttribute*)currentAttribute->next) {
                NSString* name = [NSString stringWithCString:(char*)currentAttribute->name encoding:NSUTF8StringEncoding];
                xmlChar* str = xmlNodeGetContent((xmlNode*)currentAttribute);
                NSString* value = [NSString stringWithCString:(char*)str encoding:NSUTF8StringEncoding];
                xmlFree(str);
                [attrs setValue:value forKey:name];
                if ([val isKindOfClass:[NSDictionary class]]) {
                    // Add attributes as properties of the class
                    [val setObject:value forKey:name];
                } else if (![nodes containsObject:attrs]) {
                    // Only add attributes to nodes if there actually is one.
                    [nodes addObject:attrs];
                }
            }
        } else if (currentNode->type == XML_TEXT_NODE || currentNode->type == XML_CDATA_SECTION_NODE) {
            xmlChar* str = xmlNodeGetContent(currentNode);
            NSString* part = [[NSString stringWithCString:(const char*)str encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([part length] > 0) {
                [nodes addObject:part];
            }
            xmlFree(str);
        }
    }
    if ([nodes count] == 1) {
        return [nodes objectAtIndex:0];
    }
    if ([nodes count] == 0) {
        return @"";
    }
    if (YES || [nodes containsObject:attrs]) {
        // We have both attributes and children. merge everything together.
        NSMutableDictionary* results = [NSMutableDictionary dictionary];
        for (NSDictionary* dict in nodes) {
            for (NSString* key in dict) {
                id value = [dict valueForKey:key];
                id currentValue = [results valueForKey:key];
                if (nil == currentValue) {
                    [results setValue:value forKey:key];
                } else if ([currentValue isKindOfClass:[NSMutableArray class]]) {
                    [currentValue addObject:value];
                } else {
                    NSMutableArray* array = [NSMutableArray arrayWithObjects: currentValue, value, nil];
                    [results setValue:array forKey:key];
                }
            }
        }
        return results;
    }
    return nodes;
}

- (NSDictionary*)parseXML:(NSString*)xml {
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
    doc = xmlParseMemory(buffer, (int) strlen(buffer));
    
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

- (id)objectFromString:(NSString*)string error:(NSError **)error {
    // TODO: Add error handling...
    return [self parseXML:string];
}

- (NSString*)stringFromObject:(id)object error:(NSError **)error {    
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end