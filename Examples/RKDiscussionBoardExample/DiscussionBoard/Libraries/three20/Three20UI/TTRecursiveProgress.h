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

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@protocol TTRecursiveProgressDelegate
@required
/**
 * @param progress The progress percentage within [0...1].
 */
- (void)didSetProgress:(CGFloat)progress;

@end


/**
 * A generic recursive progress object. This object makes it possible to split progress into
 * recursive chunks. Here's an example:
 *
 *  0     Standard progress bar       1
 * |-----------------------------------|
 *
 * It's possible to split this into recursive chunks like so:
 *
 *  0     Recursive progress bar       1
 * |-----------------------------------|
 *  0     1 0     1 0                 1
 * |-------|-------|-------------------|
 *                  0     1 0         1
 *                 |-------|-----------|
 *
 * Each progress object only knows about progress from 0...1. Setting the progress on any
 * object propagates the number up the tree until it's at the root node, at which point we
 * notify the delegate.
 *
 * An example: You write a method that displays progress. This method has submethods. Each
 * submethod also needs to display progress, but they need to do so in sub units.
 *
 * Coding example:
 *
 * TTRecursiveProgress* progress = [TTRecursiveProgress progressWithDelegate:self];
 * progress.percent = 0.5; // didSetProgress:0.5
 *
 * TTRecursiveProgress* subProgress = [TTRecursiveProgress
 *   progressWithParent: progress firstPercent: 0.2 lastPercent: 0.6];
 * subProgress.percent = 0.5; // didSetProgress:0.4
 */
@interface TTRecursiveProgress : NSObject {
  id<TTRecursiveProgressDelegate>  _delegate;  // Only valid in the topmost node.
  TTRecursiveProgress*              _parent;    // Only valid in child nodes.

  CGFloat _firstPercent;
  CGFloat _lastPercent;
}

/**
 * The initial percentage within the range of [0...1]
 */
@property (nonatomic) CGFloat firstPercent;

/**
 * The final percentage within the range of [0...1].
 * Should be >= firstPercent.
 */
@property (nonatomic) CGFloat lastPercent;

/**
 * Set the progress at this level and propagate it to the root node.
 * Eventually calls didSetProgress: on the delegate with a value from 0...1.
 */
@property (nonatomic) CGFloat percent;

/**
 * The root level delegate.
 */
@property (nonatomic, assign) id<TTRecursiveProgressDelegate> delegate;


+ (id)progressWithDelegate:(id<TTRecursiveProgressDelegate>)delegate;

+ (id)progressWithParent: (TTRecursiveProgress*)parent
            firstPercent: (CGFloat)firstPercent
             lastPercent: (CGFloat)lastPercent;

// Designated initializer for root nodes
- (id)initWithDelegate:(id <TTRecursiveProgressDelegate>)delegate;

// Designated initializer for child nodes
- (id)initWithParent:(TTRecursiveProgress*)parent
        firstPercent: (CGFloat)firstPercent
         lastPercent: (CGFloat)lastPercent;

@end
