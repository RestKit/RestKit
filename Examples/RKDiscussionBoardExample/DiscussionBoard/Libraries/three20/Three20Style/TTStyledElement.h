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

// Style
#import "Three20Style/TTStyledNode.h"

@interface TTStyledElement : TTStyledNode {
  TTStyledNode* _firstChild;
  TTStyledNode* _lastChild;
  NSString*     _className;
}

@property (nonatomic, readonly) TTStyledNode* firstChild;
@property (nonatomic, readonly) TTStyledNode* lastChild;
@property (nonatomic, retain)   NSString*     className;

- (id)initWithText:(NSString*)text;

// Designated initializer
- (id)initWithText:(NSString*)text next:(TTStyledNode*)nextSibling;

- (void)addChild:(TTStyledNode*)child;
- (void)addText:(NSString*)text;
- (void)replaceChild:(TTStyledNode*)oldChild withChild:(TTStyledNode*)newChild;

- (TTStyledNode*)getElementByClassName:(NSString*)className;

@end
