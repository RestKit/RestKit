//
// Copyright 2009-2010 Facebook
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
#import <UIKit/UIKit.h>

@class TTStyledNode;
@class TTStyledElement;

#if __IPHONE_4_0 && __IPHONE_4_0 <= __IPHONE_OS_VERSION_MAX_ALLOWED
@interface TTStyledTextParser : NSObject <NSXMLParserDelegate> {
#else
@interface TTStyledTextParser : NSObject {
#endif
  TTStyledNode*     _rootNode;
  TTStyledElement*  _topElement;
  TTStyledNode*     _lastNode;

  NSError*          _parserError;

  NSMutableString*  _chars;
  NSMutableArray*   _stack;

  BOOL _parseLineBreaks;
  BOOL _parseURLs;
}

@property (nonatomic, retain) TTStyledNode* rootNode;
@property (nonatomic)         BOOL          parseLineBreaks;
@property (nonatomic)         BOOL          parseURLs;

- (void)parseXHTML:(NSString*)html;
- (void)parseText:(NSString*)string;

@end
