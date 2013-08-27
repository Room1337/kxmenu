//
//  KxMenu.h
//  kxmenu project
//  https://github.com/kolyvan/kxmenu/
//
//  Created by Kolyvan on 17.05.13.
//

/*
 Copyright (c) 2013 Konstantin Bukreev. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import <Foundation/Foundation.h>

@interface KxMenuItem : NSObject

// for compatibility with iOS4 use retain|copy instead of strong, unsafe_unretained instead of weak
@property (readwrite, nonatomic, retain) UIImage *image;
@property (readwrite, nonatomic, copy) NSString *title;
@property (readwrite, nonatomic, unsafe_unretained) id target;
@property (readwrite, nonatomic, assign) SEL action;
@property (readwrite, nonatomic, retain) UIColor *foreColor;
@property (readwrite, nonatomic, assign) NSTextAlignment alignment;

+ (instancetype) menuItem:(NSString *) title
                    image:(UIImage *) image
                   target:(id)target
                   action:(SEL) action;

@end


typedef enum {
	KxMenuViewArrowDirectionNone,
    KxMenuViewArrowDirectionUp,
    KxMenuViewArrowDirectionDown,
    KxMenuViewArrowDirectionLeft,
    KxMenuViewArrowDirectionRight,
} KxMenuViewArrowDirection;

@protocol KxMenuDrawProtocol
// optional draw method for KxMenu subclasses to override, don't call super
@optional
- (CGFloat)arrowSize;
- (CGFloat)innerBorder;
- (void) setupBackgroundWithSize:(CGSize)size
                          inView:(UIView *)view
              withArrowDirection:(KxMenuViewArrowDirection)arrowDirection
                     andPosition:(CGFloat)arrowPosition;

- (void) drawBackgroundWithSize:(CGSize)size
                      inContext:(CGContextRef)ref
             withArrowDirection:(KxMenuViewArrowDirection)arrowDirection
                    andPosition:(CGFloat)arrowPosition;
@end

@interface KxMenu : NSObject <KxMenuDrawProtocol>

+ (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
          withMenuItems:(NSArray *)menuItems;

+ (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
        withOrientation:(UIInterfaceOrientation)orientation
              menuItems:(NSArray *)menuItems;

+ (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
            withSubview:(UIView *)contentView;

+ (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
        withOrientation:(UIInterfaceOrientation)orientation
                subview:(UIView *)contentView;

+ (void) dismissMenu;

+ (UIColor *) tintColor;
+ (void) setTintColor: (UIColor *) tintColor;

+ (UIFont *) titleFont;
+ (void) setTitleFont: (UIFont *) titleFont;

// instead of calling the class methods which use a menu singleton,
// can subclass to override draw method then directly call its
// instance method variants of show/dismiss
- (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
          withMenuItems:(NSArray *)menuItems;

- (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
        withOrientation:(UIInterfaceOrientation)orientation
              menuItems:(NSArray *)menuItems;

- (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
            withSubview:(UIView *)contentView;

- (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
        withOrientation:(UIInterfaceOrientation)orientation
                subview:(UIView *)contentView;

- (void) dismissMenu; // subclasses can override, should call super

// for compatibility with old demo code, "menuItems" instead of "withMenuItems"
+ (void) showMenuInView:(UIView *)view fromRect:(CGRect)rect menuItems:(NSArray *)menuItems;

@end
