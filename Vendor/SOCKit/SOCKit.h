//
// Copyright 2011 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

/**
 * String <-> Object Coding.
 *
 * Code information from strings into objects and vice versa.
 *
 * A pattern is a string with parameter names prefixed by colons (":").
 * An example of a pattern string with one parameter named :username is:
 * api.github.com/users/:username/gists
 *
 * Patterns, once created, can be used to efficiently turn objects into strings and
 * vice versa. Respectively, these techniques are referred to as inbound and outbound.
 *
 * Inbound example (turn an object into a string):
 *
 *   pattern: api.github.com/users/:username/gists
 *   > [pattern stringFromObject:githubUser];
 *   returns: api.github.com/users/jverkoey/gists
 *
 *   pattern: api.github.com/repos/:username/:repo/issues
 *   > [pattern stringFromObject:githubRepo];
 *   returns: api.github.com/repos/jverkoey/sockit/issues
 *
 * Outbound example (turn a string into an object):
 *
 *   pattern: github.com/:username
 *   > [pattern performSelector:@selector(initWithUsername:) onObject:[GithubUser class] sourceString:@"github.com/jverkoey"];
 *   returns: an allocated, initialized, and autoreleased GithubUser object with @"jverkoey" passed
 *            to the initWithUsername: method.
 *
 *   pattern: github.com/:username/:repo
 *   > [pattern performSelector:@selector(initWithUsername:repoName:) onObject:[GithubUser class] sourceString:@"github.com/jverkoey/sockit"];
 *   returns: an allocated, initialized, and autoreleased GithubUser object with @"jverkoey" and
 *            @"sockit" passed to the initWithUsername:repoName: method.
 *
 *   pattern: github.com/:username
 *   > [pattern performSelector:@selector(setUsername:) onObject:githubUser sourceString:@"github.com/jverkoey"];
 *   returns: nil because setUsername: does not have a return value. githubUser's username property
 *            is now @"jverkoey".
 *
 * Note:
 *
 *      Pattern parameters must be separated by some sort of non-parameter character.
 *      This means that you can't define a pattern like :user:repo. This is because when we
 *      get around to wanting to decode the string back into an object we need some sort of
 *      delimiter between the parameters.
 *
 * Note 2:
 *
 *      If you have colons in your text that aren't followed by a valid parameter name then the
 *      colon will be treated as static text. This is handy if you're defining a URL pattern.
 *      For example: @"http://github.com/:user" only has one parameter, :user. The ":" in http://
 *      is ignored.
 */
@interface SOCPattern : NSObject {
@private
  NSString* _patternString;
  NSArray* _tokens;
  NSArray* _parameters;
}

/**
 * Initializes a newly allocated pattern object with the given pattern string.
 */
- (id)initWithString:(NSString *)string;
+ (id)patternWithString:(NSString *)string;

/**
 * Returns YES if the given string can be used with performSelector:onObject:sourceString: or
 * extractParameterKeyValuesFromSourceString:.
 *
 * A matching string must exactly match all of the static portions of the pattern and provide
 * values for each of the parameters.
 *
 *      @param string  A string that may or may not conform to this pattern.
 *      @returns YES if the given string conforms to this pattern, NO otherwise.
 */
- (BOOL)stringMatches:(NSString *)string;

/**
 * Performs the given selector on the object with the matching parameter values from sourceString.
 *
 *      @param selector       The selector to perform on the object. If there aren't enough
 *                            parameters in the pattern then the excess parameters in the selector
 *                            will be nil.
 *      @param object         The object to perform the selector on.
 *      @param sourceString   A string that conforms to this pattern. The parameter values from
 *                            this string are used as the arguments when performing the selector
 *                            on the object.
 *      @returns The initialized, autoreleased object if the selector is an initializer
 *               (prefixed with "init") and object is a Class, otherwise the return value from
 *               invoking the selector.
 */
- (id)performSelector:(SEL)selector onObject:(id)object sourceString:(NSString *)sourceString;

/**
 * Extracts the matching parameter values from sourceString into an NSDictionary.
 *
 *      @param sourceString  A string that conforms to this pattern. The parameter values from
 *                           this string are extracted into the NSDictionary.
 *      @returns A dictionary of key value pairs. All values will be NSStrings. The keys will
 *               correspond to the pattern's parameter names. Duplicate key values will be
 *               written over by later values.
 */
- (NSDictionary *)extractParameterKeyValuesFromSourceString:(NSString *)sourceString;

/**
 * Returns a string with the parameters of this pattern replaced using Key-Value Coding (KVC)
 * on the receiving object.
 *
 * Parameters of the pattern are evaluated using valueForKeyPath:. See Apple's KVC documentation
 * for more details.
 *
 * Key-Value Coding Fundamentals:
 * http://developer.apple.com/library/ios/#documentation/cocoa/conceptual/KeyValueCoding/Articles/BasicPrinciples.html#//apple_ref/doc/uid/20002170-BAJEAIEE
 *
 * Collection Operators:
 * http://developer.apple.com/library/ios/#documentation/cocoa/conceptual/KeyValueCoding/Articles/CollectionOperators.html#//apple_ref/doc/uid/20002176-BAJEAIEE
 */
- (NSString *)stringFromObject:(id)object;

@end

/**
 * A convenience method for:
 *
 * SOCPattern* pattern = [SOCPattern patternWithString:string];
 * NSString* result = [pattern stringFromObject:object];
 *
 * @see documentation for stringFromObject:
 */
NSString* SOCStringFromStringWithObject(NSString* string, id object);
