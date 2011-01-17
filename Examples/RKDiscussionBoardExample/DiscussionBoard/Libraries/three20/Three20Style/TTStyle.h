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

@class TTStyleContext;

@interface TTStyle : NSObject {
  TTStyle* _next;
}

@property (nonatomic, retain) TTStyle* next;

- (id)initWithNext:(TTStyle*)next;

- (TTStyle*)next:(TTStyle*)next;

- (void)draw:(TTStyleContext*)context;

- (UIEdgeInsets)addToInsets:(UIEdgeInsets)insets forSize:(CGSize)size;
- (CGSize)addToSize:(CGSize)size context:(TTStyleContext*)context;

- (void)addStyle:(TTStyle*)style;

- (id)firstStyleOfClass:(Class)cls;
- (id)styleForPart:(NSString*)name;

@end
