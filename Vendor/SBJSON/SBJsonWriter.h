/*
 Copyright (C) 2009 Stig Brautaset. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
   to endorse or promote products derived from this software without specific
   prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import "SBJsonBase.h"

/**
 @brief The JSON writer class.
 
 Objective-C types are mapped to JSON types in the following way:
 
 @li NSNull -> Null
 @li NSString -> String
 @li NSArray -> Array
 @li NSDictionary -> Object
 @li NSNumber (-initWithBool:) -> Boolean
 @li NSNumber -> Number
 
 In JSON the keys of an object must be strings. NSDictionary keys need
 not be, but attempting to convert an NSDictionary with non-string keys
 into JSON will throw an exception.
 
 NSNumber instances created with the +initWithBool: method are
 converted into the JSON boolean "true" and "false" values, and vice
 versa. Any other NSNumber instances are converted to a JSON number the
 way you would expect.
 
 */
@interface SBJsonWriter : SBJsonBase {

@private
    BOOL sortKeys, humanReadable;
}

/**
 @brief Whether we are generating human-readable (multiline) JSON.
 
 Set whether or not to generate human-readable JSON. The default is NO, which produces
 JSON without any whitespace. (Except inside strings.) If set to YES, generates human-readable
 JSON with linebreaks after each array value and dictionary key/value pair, indented two
 spaces per nesting level.
 */
@property BOOL humanReadable;

/**
 @brief Whether or not to sort the dictionary keys in the output.
 
 If this is set to YES, the dictionary keys in the JSON output will be in sorted order.
 (This is useful if you need to compare two structures, for example.) The default is NO.
 */
@property BOOL sortKeys;

/**
 @brief Return JSON representation (or fragment) for the given object.
 
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p *error can be interrogated to find the cause of the error.
 
 @param value any instance that can be represented as a JSON fragment
 
 */
- (NSString*)stringWithObject:(id)value;

/**
 @brief Return JSON representation (or fragment) for the given object.
 
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p *error can be interrogated to find the cause of the error.
 
 @param value any instance that can be represented as a JSON fragment
 @param error pointer to object to be populated with NSError on failure
 
 */- (NSString*)stringWithObject:(id)value
                           error:(NSError**)error;


@end

/**
 @brief Allows generation of JSON for otherwise unsupported classes.
 
 If you have a custom class that you want to create a JSON representation for you can implement
 this method in your class. It should return a representation of your object defined
 in terms of objects that can be translated into JSON. For example, a Person
 object might implement it like this:
 
 @code
 - (id)proxyForJson {
    return [NSDictionary dictionaryWithObjectsAndKeys:
        name, @"name",
        phone, @"phone",
        email, @"email",
        nil];
 }
 @endcode
 
 */
@interface NSObject (SBProxyForJson)
- (id)proxyForJson;
@end

