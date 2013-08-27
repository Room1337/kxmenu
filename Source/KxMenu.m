//
//  KxMenu.m
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

/*
 Some ideas was taken from QBPopupMenu project by Katsuma Tanaka.
 https://github.com/questbeat/QBPopupMenu
*/

#import "KxMenu.h"
#import <QuartzCore/QuartzCore.h>

#ifndef ah_retain
#if __has_feature(objc_arc)
#define ah_retain self
#define ah_dealloc self
#define release self
#define autorelease self
#else
#define ah_retain retain
#define ah_dealloc dealloc
#endif
#endif

const CGFloat kArrowSize = 12.f;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@interface KxMenuView : UIView
@end

@interface KxMenuOverlay : UIView
@end

@implementation KxMenuOverlay

// - (void) dealloc { NSLog(@"dealloc %@", self); }

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIView *touched = [[touches anyObject] view];
    if (touched == self) {
        
        for (UIView *v in self.subviews) {
            if ([v isKindOfClass:[KxMenuView class]]
                && [v respondsToSelector:@selector(dismissMenu:)]) {
                
                [v performSelector:@selector(dismissMenu:) withObject:@(YES)];
            }
        }
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@implementation KxMenuItem

+ (instancetype) menuItem:(NSString *) title
                    image:(UIImage *) image
                   target:(id)target
                   action:(SEL) action
{
    return [[KxMenuItem alloc] init:title
                              image:image
                             target:target
                             action:action];
}

- (id) init:(NSString *) title
      image:(UIImage *) image
     target:(id)target
     action:(SEL) action
{
    NSParameterAssert(title.length || image);
    
    self = [super init];
    if (self) {
        
        _title = title;
        _image = image;
        _target = target;
        _action = action;
    }
    return self;
}

- (void) dealloc {
    //NSLog(@"dealloc %@", self);
    self.title = nil;
    self.image = nil;
    self.foreColor = nil;
    [super ah_dealloc];
}

- (BOOL) enabled
{
    return _target != nil && _action != NULL;
}

- (void) performAction
{
    __strong id target = self.target;
    
    if (target && [target respondsToSelector:_action]) {
        
        [target performSelectorOnMainThread:_action withObject:self waitUntilDone:YES];
    }
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@ #%p %@>", [self class], self, _title];
}

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@implementation KxMenuView {
    
    KxMenuViewArrowDirection    _arrowDirection;
    CGFloat                     _arrowPosition;
    CGPoint                     _arrowPoint;
    UIView                      *_contentView;
    NSArray                     *_menuItems;
    KxMenu                      *_owner;
}

- (id)initWithOwner:(KxMenu *)menu
{
    self = [super initWithFrame:CGRectZero];    
    if(self) {

        self.backgroundColor = [UIColor clearColor];
        self.opaque = YES;
        self.alpha = 0;
        
        self.layer.shadowOpacity = 0.5;
        self.layer.shadowOffset = CGSizeMake(2, 2);
        self.layer.shadowRadius = 2;
        
        _owner = menu;
    }
    
    return self;
}

- (void) dealloc {
    //NSLog(@"dealloc %@", self);
    [_menuItems release];
    [super ah_dealloc];
}

- (void) setupFrameInView:(UIView *)view
                 fromRect:(CGRect)fromRect
          withOrientation:(UIInterfaceOrientation)orientation
{
    CGFloat arrowSize = ([_owner respondsToSelector:@selector(arrowSize)]) ? _owner.arrowSize : kArrowSize;
    CGFloat innerBorder = ([_owner respondsToSelector:@selector(innerBorder)]) ? _owner.innerBorder : 0;
    
    const CGSize contentSize = _contentView.frame.size;
    const CGSize borderedContentSize = CGSizeMake(contentSize.width + innerBorder + innerBorder, contentSize.height + innerBorder + innerBorder);
    
    const CGFloat outerWidth = view.bounds.size.width;
    const CGFloat outerHeight = view.bounds.size.height;
    
    const CGFloat rectX0 = fromRect.origin.x;
    const CGFloat rectX1 = fromRect.origin.x + fromRect.size.width;
    const CGFloat rectXM = fromRect.origin.x + fromRect.size.width * 0.5f;
    const CGFloat rectY0 = fromRect.origin.y;
    const CGFloat rectY1 = fromRect.origin.y + fromRect.size.height;
    const CGFloat rectYM = fromRect.origin.y + fromRect.size.height * 0.5f;;
    
    const CGFloat widthPlusArrow = borderedContentSize.width + arrowSize;
    const CGFloat heightPlusArrow = borderedContentSize.height + arrowSize;
    const CGFloat widthHalf = borderedContentSize.width * 0.5f;
    const CGFloat heightHalf = borderedContentSize.height * 0.5f;
    
    const CGFloat kMargin = 5.f;
    
    // no rotation
    switch(orientation) {
    case UIInterfaceOrientationPortrait:
    default:
        if (heightPlusArrow < (outerHeight - rectY1)) {
        
            _arrowDirection = KxMenuViewArrowDirectionUp;
            CGPoint point = (CGPoint){
                rectXM - widthHalf,
                rectY1
            };
            
            if (point.x < kMargin)
                point.x = kMargin;
            
            if ((point.x + borderedContentSize.width + kMargin) > outerWidth)
                point.x = outerWidth - borderedContentSize.width - kMargin;
            
            _arrowPosition = rectXM - point.x;
            _arrowPoint = (CGPoint){ _arrowPosition, 0 };
            //_arrowPosition = MAX(16, MIN(_arrowPosition, borderedContentSize.width - 16));        
            _contentView.frame = (CGRect){innerBorder, arrowSize + innerBorder, contentSize};
                    
            self.frame = (CGRect) {
                
                point,
                borderedContentSize.width,
                borderedContentSize.height + arrowSize
            };
            
        } else if (heightPlusArrow < rectY0) {
            
            _arrowDirection = KxMenuViewArrowDirectionDown;
            CGPoint point = (CGPoint){
                rectXM - widthHalf,
                rectY0 - heightPlusArrow
            };
            
            if (point.x < kMargin)
                point.x = kMargin;
            
            if ((point.x + borderedContentSize.width + kMargin) > outerWidth)
                point.x = outerWidth - borderedContentSize.width - kMargin;
            
            _arrowPosition = rectXM - point.x;
            _arrowPoint = (CGPoint){ _arrowPosition, borderedContentSize.height };
            _contentView.frame = (CGRect){innerBorder, innerBorder, contentSize};
            
            self.frame = (CGRect) {
                
                point,
                borderedContentSize.width,
                borderedContentSize.height + arrowSize
            };
            
        } else if (widthPlusArrow < (outerWidth - rectX1)) {
            
            _arrowDirection = KxMenuViewArrowDirectionLeft;
            CGPoint point = (CGPoint){
                rectX1,
                rectYM - heightHalf
            };
            
            if (point.y < kMargin)
                point.y = kMargin;
            
            if ((point.y + borderedContentSize.height + kMargin) > outerHeight)
                point.y = outerHeight - borderedContentSize.height - kMargin;
            
            _arrowPosition = rectYM - point.y;
            _arrowPoint = (CGPoint){ 0, _arrowPosition };
            _contentView.frame = (CGRect){arrowSize + innerBorder, innerBorder, contentSize};
            
            self.frame = (CGRect) {
                
                point,
                borderedContentSize.width + arrowSize,
                borderedContentSize.height
            };
            
        } else if (widthPlusArrow < rectX0) {
            
            _arrowDirection = KxMenuViewArrowDirectionRight;
            CGPoint point = (CGPoint){
                rectX0 - widthPlusArrow,
                rectYM - heightHalf
            };
            
            if (point.y < kMargin)
                point.y = kMargin;
            
            if ((point.y + borderedContentSize.height + 5) > outerHeight)
                point.y = outerHeight - borderedContentSize.height - kMargin;
            
            _arrowPosition = rectYM - point.y;
            _arrowPoint = (CGPoint){ borderedContentSize.width, _arrowPosition };
            _contentView.frame = (CGRect){innerBorder, innerBorder, contentSize};
            
            self.frame = (CGRect) {
                
                point,
                borderedContentSize.width  + arrowSize,
                borderedContentSize.height
            };
            
        } else {
            
            _arrowDirection = KxMenuViewArrowDirectionNone;
            _arrowPosition = 0;
            _arrowPoint = (CGPoint){ borderedContentSize.width * 0.5f, borderedContentSize.height * 0.5f };
            _contentView.frame = (CGRect){innerBorder, innerBorder, contentSize};
            
            self.frame = (CGRect) {
                
                (outerWidth - borderedContentSize.width)   * 0.5f,
                (outerHeight - borderedContentSize.height) * 0.5f,
                borderedContentSize,
            };
        }
        break;
        
        
        
    case UIInterfaceOrientationPortraitUpsideDown:
        if (heightPlusArrow < (outerHeight - rectY1)) {
            
            _arrowDirection = KxMenuViewArrowDirectionDown;
            _contentView.frame = (CGRect){innerBorder, innerBorder, contentSize};
            
            CGPoint point = (CGPoint){
                rectXM - widthHalf,
                rectY1 - heightPlusArrow
            };
            
            if (rectXM - widthHalf < kMargin)
                point.x -= kMargin - (rectXM - widthHalf);
                
            else if ((rectXM - widthHalf) + borderedContentSize.width > outerWidth - kMargin)
                point.x += ((rectXM - widthHalf) + borderedContentSize.width) - (outerWidth - kMargin);
            
            _arrowPosition = rectXM - point.x;
            _arrowPoint = (CGPoint){ _arrowPosition, borderedContentSize.height };
            
            // the order that the following 3 properties are set absolutely matters,
            // any order other than anchorPoint, frame, transform and the view is positioned and/or sized incorrectly
            self.layer.anchorPoint = CGPointMake(_arrowPosition / borderedContentSize.width, 1.0);
            
            self.frame = (CGRect) {
                point,
                borderedContentSize.width,
                borderedContentSize.height + arrowSize
            };
            
        } else if (heightPlusArrow < rectY0) {
            
            _arrowDirection = KxMenuViewArrowDirectionUp;
            _contentView.frame = (CGRect){innerBorder, arrowSize + innerBorder, contentSize};
            
            CGPoint point = (CGPoint){
                rectXM - widthHalf,
                rectY0
            };
            
            if (rectXM - widthHalf < kMargin)
                point.x -= kMargin - (rectXM - widthHalf);
                
            else if ((rectXM - widthHalf) + borderedContentSize.width > outerWidth - kMargin)
                point.x += ((rectXM - widthHalf) + borderedContentSize.width) - (outerWidth - kMargin);
            
            _arrowPosition = rectXM - point.x;
            _arrowPoint = (CGPoint){ _arrowPosition, 0 };
            
            // the order that the following 3 properties are set absolutely matters,
            // any order other than anchorPoint, frame, transform and the view is positioned and/or sized incorrectly
            self.layer.anchorPoint = CGPointMake(_arrowPosition / borderedContentSize.width, 0.0);
            
            self.frame = (CGRect) {
                point,
                borderedContentSize.width,
                borderedContentSize.height + arrowSize
            };
            
        } else if (widthPlusArrow < (outerWidth - rectX1)) {
            
            _arrowDirection = KxMenuViewArrowDirectionRight;
            _contentView.frame = (CGRect){innerBorder, innerBorder, contentSize};
            
            CGPoint point = (CGPoint){
                rectX1 - widthPlusArrow,
                rectYM - heightHalf
            };
            
            // these point.y manipulations are probably not correct:
            if (point.y < kMargin)
                point.y = kMargin;
            
            if ((point.y + borderedContentSize.height + kMargin) > outerHeight)
                point.y = outerHeight - borderedContentSize.height - kMargin;
            
            _arrowPosition = rectYM - point.y;
            _arrowPoint = (CGPoint){ borderedContentSize.width, _arrowPosition };
            
            // the order that the following 3 properties are set absolutely matters,
            // any order other than anchorPoint, frame, transform and the view is positioned and/or sized incorrectly
            self.layer.anchorPoint = CGPointMake(1.0, _arrowPosition / borderedContentSize.height);
            
            self.frame = (CGRect) {
                point,
                borderedContentSize.width + arrowSize,
                borderedContentSize.height
            };
            
        } else if (widthPlusArrow < rectX0) {
            
            _arrowDirection = KxMenuViewArrowDirectionLeft;
            _contentView.frame = (CGRect){arrowSize + innerBorder, innerBorder, contentSize};
            
            CGPoint point = (CGPoint){
                rectX0,
                rectYM - heightHalf
            };
            
            // these point.y manipulations are probably not correct:
            if (point.y < kMargin)
                point.y = kMargin;
            
            if ((point.y + borderedContentSize.height + 5) > outerHeight)
                point.y = outerHeight - borderedContentSize.height - kMargin;
            
            _arrowPosition = rectYM - point.y;
            _arrowPoint = (CGPoint){ 0, _arrowPosition };
            
            // the order that the following 3 properties are set absolutely matters,
            // any order other than anchorPoint, frame, transform and the view is positioned and/or sized incorrectly
            self.layer.anchorPoint = CGPointMake(0.0, _arrowPosition / borderedContentSize.height);
            
            self.frame = (CGRect) {
                point,
                borderedContentSize.width + arrowSize,
                borderedContentSize.height
            };
            
        } else {
            
            _arrowDirection = KxMenuViewArrowDirectionNone;
            _arrowPosition = 0;
            _arrowPoint = (CGPoint){ borderedContentSize.width * 0.5f, borderedContentSize.height * 0.5f };
            _contentView.frame = (CGRect){innerBorder, innerBorder, contentSize};
            
            self.frame = (CGRect) {
                (outerWidth - borderedContentSize.width)   * 0.5f,
                (outerHeight - borderedContentSize.height) * 0.5f,
                borderedContentSize,
            };
        }
        
        self.transform = CGAffineTransformMakeRotation(M_PI);
        break;
        
        
        
    case UIInterfaceOrientationLandscapeRight:
        if (widthPlusArrow < (outerHeight - rectY1)) {
            
            _arrowDirection = KxMenuViewArrowDirectionLeft;
            _contentView.frame = (CGRect){arrowSize + innerBorder, innerBorder, contentSize};
            
            CGPoint point = (CGPoint){
                rectXM,
                rectY1 - heightHalf
            };
            
            if (rectXM - heightHalf < kMargin)
                point.y -= kMargin - (rectXM - heightHalf);
                
            else if (rectXM + heightHalf > outerWidth - kMargin)
                point.y += (rectXM + heightHalf) - (outerWidth - kMargin);
            
            _arrowPosition = rectY1 - point.y;
            _arrowPoint = (CGPoint){ 0, _arrowPosition };
            
            // the order that the following 3 properties are set absolutely matters (the last one, transform, is further below),
            // any order other than anchorPoint, frame, transform and the view is positioned and/or sized incorrectly
            self.layer.anchorPoint = CGPointMake(0.0, _arrowPosition / borderedContentSize.height);
            
            self.frame = (CGRect) {
                point,
                borderedContentSize.width + arrowSize,
                borderedContentSize.height
            };
            
        } else if (widthPlusArrow < rectY0) {
            
            _arrowDirection = KxMenuViewArrowDirectionRight;
            _contentView.frame = (CGRect){innerBorder, innerBorder, contentSize};
            
            CGPoint point = (CGPoint){
                rectXM - widthPlusArrow,
                rectY0 - heightHalf
            };
            
            if (rectXM - heightHalf < kMargin)
                point.y -= kMargin - (rectXM - heightHalf);
                
            else if (rectXM + heightHalf > outerWidth - kMargin)
                point.y += (rectXM + heightHalf) - (outerWidth - kMargin);
            
            _arrowPosition = rectY0 - point.y;
            _arrowPoint = (CGPoint){ borderedContentSize.width, _arrowPosition };
            
            // the order that the following 3 properties are set absolutely matters (the last one, transform, is further below),
            // any order other than anchorPoint, frame, transform and the view is positioned and/or sized incorrectly
            self.layer.anchorPoint = CGPointMake(1.0, _arrowPosition / borderedContentSize.height);
            
            self.frame = (CGRect) {
                point,
                borderedContentSize.width + arrowSize,
                borderedContentSize.height
            };
            
        } else {
            
            _arrowDirection = KxMenuViewArrowDirectionNone;
            _arrowPosition = 0;
            _arrowPoint = (CGPoint){ borderedContentSize.width * 0.5f, borderedContentSize.height * 0.5f };
            _contentView.frame = (CGRect){innerBorder, innerBorder, contentSize};
            
            self.frame = (CGRect) {
                (outerWidth - borderedContentSize.width)   * 0.5f,
                (outerHeight - borderedContentSize.height) * 0.5f,
                borderedContentSize,
            };
        }
        
        self.transform = CGAffineTransformMakeRotation(M_PI_2);
        break;
        
        
        
    case UIInterfaceOrientationLandscapeLeft:
        if (widthPlusArrow < rectY0) {
            
            _arrowDirection = KxMenuViewArrowDirectionLeft;
            _contentView.frame = (CGRect){arrowSize + innerBorder, innerBorder, contentSize};
            
            CGPoint point = (CGPoint){
                rectXM,
                rectY0 - heightHalf
            };
            
            if (rectXM - heightHalf < kMargin)
                point.y += kMargin - (rectXM - heightHalf);
                
            else if (rectXM + heightHalf > outerWidth - kMargin)
                point.y -= (rectXM + heightHalf) - (outerWidth - kMargin);
            
            _arrowPosition = rectY0 - point.y;
            _arrowPoint = (CGPoint){ 0, _arrowPosition };
            
            // the order that the following 3 properties are set absolutely matters (the last one, transform, is further below),
            // any order other than anchorPoint, frame, transform and the view is positioned and/or sized incorrectly
            self.layer.anchorPoint = CGPointMake(0.0, _arrowPosition / borderedContentSize.height);
            
            self.frame = (CGRect) {
                point,
                borderedContentSize.width + arrowSize,
                borderedContentSize.height
            };
            
        } else if (widthPlusArrow < (outerHeight - rectY1)) {
            
            _arrowDirection = KxMenuViewArrowDirectionRight;
            _contentView.frame = (CGRect){innerBorder, innerBorder, contentSize};
            
            CGPoint point = (CGPoint){
                rectXM - widthPlusArrow,
                rectY1 - heightHalf
            };
            
            if (rectXM - heightHalf < kMargin)
                point.y += kMargin - (rectXM - heightHalf);
                
            else if (rectXM + heightHalf > outerWidth - kMargin)
                point.y -= (rectXM + heightHalf) - (outerWidth - kMargin);
            
            _arrowPosition = rectY1 - point.y;
            _arrowPoint = (CGPoint){ borderedContentSize.width, _arrowPosition };
            
            // the order that the following 3 properties are set absolutely matters (the last one, transform, is further below),
            // any order other than anchorPoint, frame, transform and the view is positioned and/or sized incorrectly
            self.layer.anchorPoint = CGPointMake(1.0, _arrowPosition / borderedContentSize.height);
            
            self.frame = (CGRect) {
                point,
                borderedContentSize.width + arrowSize,
                borderedContentSize.height
            };
            
        } else {
            
            _arrowDirection = KxMenuViewArrowDirectionNone;
            _arrowPosition = 0;
            _arrowPoint = (CGPoint){ borderedContentSize.width * 0.5f, borderedContentSize.height * 0.5f };
            _contentView.frame = (CGRect){innerBorder, innerBorder, contentSize};
            
            self.frame = (CGRect) {
                (outerWidth - borderedContentSize.width)   * 0.5f,
                (outerHeight - borderedContentSize.height) * 0.5f,
                borderedContentSize,
            };
        }
        
        self.transform = CGAffineTransformMakeRotation(-M_PI_2);
        break;
    }
}

- (void)showMenuInView:(UIView *)view
              fromRect:(CGRect)rect
       withOrientation:(UIInterfaceOrientation)orientation
             menuItems:(NSArray *)menuItems
{
    _menuItems = [menuItems copy];
    
    _contentView = [self createContentView];
    [self addSubview:_contentView];
    
    [self setupFrameInView:view fromRect:rect withOrientation:orientation];
    
    KxMenuOverlay *overlay = [[KxMenuOverlay alloc] initWithFrame:view.bounds];
    [overlay addSubview:self];
    [view addSubview:overlay];
    [overlay release];
    
    if ([_owner respondsToSelector:@selector(setupBackgroundWithSize:inView:withArrowDirection:andPosition:)])
        [_owner setupBackgroundWithSize:self.bounds.size
                                 inView:self
                     withArrowDirection:_arrowDirection
                            andPosition:_arrowPosition];
    
    // i can't seem to get this to work correctly
//    _contentView.hidden = YES;
//    const CGRect toBounds = self.bounds;
//    self.bounds = CGRectZero;
//    
//    [UIView animateWithDuration:0.2
//                     animations:^(void) {
//                         
//                         self.alpha = 1.0f;
//                         self.bounds = toBounds;
//                         
//                     } completion:^(BOOL completed) {
//                         _contentView.hidden = NO;
//                     }];
    [UIView animateWithDuration:0.2
                     animations:^(void) {
                         self.alpha = 1.0f;
                     } completion:NULL];
    
}

- (void)showMenuInView:(UIView *)view
              fromRect:(CGRect)rect
       withOrientation:(UIInterfaceOrientation)orientation
               subview:(UIView *)contentView
{
    _contentView = contentView;
    [self addSubview:_contentView];
    
    [self setupFrameInView:view fromRect:rect withOrientation:orientation];
    
    KxMenuOverlay *overlay = [[KxMenuOverlay alloc] initWithFrame:view.bounds];
    [overlay addSubview:self];
    [view addSubview:overlay];
    [overlay release];
    
    if ([_owner respondsToSelector:@selector(setupBackgroundWithSize:inView:withArrowDirection:andPosition:)])
        [_owner setupBackgroundWithSize:self.bounds.size
                                 inView:self
                     withArrowDirection:_arrowDirection
                            andPosition:_arrowPosition];
    
    // i can't seem to get this to work correctly
//    _contentView.hidden = YES;
//    const CGRect toBounds = self.bounds;
//    self.bounds = CGRectZero;
//    
//    [UIView animateWithDuration:0.2
//                     animations:^(void) {
//                         
//                         self.alpha = 1.0f;
//                         self.bounds = toBounds;
//                         
//                     } completion:^(BOOL completed) {
//                         _contentView.hidden = NO;
//                     }];
    [UIView animateWithDuration:0.2
                     animations:^(void) {
                         self.alpha = 1.0f;
                     } completion:NULL];
    
}

- (void)dismissMenu:(BOOL) animated
{
    if (self.superview) {
     
        if (animated) {
            
            // i can't seem to get this to work correctly
            //_contentView.hidden = YES;
            //const CGRect toBounds = CGRectZero;
            
            [UIView animateWithDuration:0.2
                             animations:^(void) {
                                 
                                 self.alpha = 0;
                                 //self.bounds = toBounds;
                                 
                             } completion:^(BOOL finished) {
                                 
                                 if ([self.superview isKindOfClass:[KxMenuOverlay class]])
                                     [self.superview removeFromSuperview];
                                 [self removeFromSuperview];
                             }];
            
        } else {
            
            if ([self.superview isKindOfClass:[KxMenuOverlay class]])
                [self.superview removeFromSuperview];
            [self removeFromSuperview];
        }
    }
}

- (void)performAction:(id)sender
{
    [self dismissMenu:YES];
    
    UIButton *button = (UIButton *)sender;
    KxMenuItem *menuItem = _menuItems[button.tag];
    [menuItem performAction];
}

- (UIView *) createContentView
{
    for (UIView *v in self.subviews) {
        [v removeFromSuperview];
    }
    
    if (!_menuItems.count)
        return nil;
 
    const CGFloat kMinMenuItemHeight = 32.f;
    const CGFloat kMinMenuItemWidth = 32.f;
    const CGFloat kMarginX = 10.f;
    const CGFloat kMarginY = 5.f;
    
    UIFont *titleFont = [KxMenu titleFont];
    if (!titleFont) titleFont = [UIFont boldSystemFontOfSize:16];
    
    CGFloat maxImageWidth = 0;    
    CGFloat maxItemHeight = 0;
    CGFloat maxItemWidth = 0;
    
    for (KxMenuItem *menuItem in _menuItems) {
        
        const CGSize imageSize = menuItem.image.size;        
        if (imageSize.width > maxImageWidth)
            maxImageWidth = imageSize.width;        
    }
    
    for (KxMenuItem *menuItem in _menuItems) {

        const CGSize titleSize = [menuItem.title sizeWithFont:titleFont];
        const CGSize imageSize = menuItem.image.size;

        const CGFloat itemHeight = MAX(titleSize.height, imageSize.height) + kMarginY * 2;
        const CGFloat itemWidth = (menuItem.image ? maxImageWidth + kMarginX : 0) + titleSize.width + kMarginX * 4;
        
        if (itemHeight > maxItemHeight)
            maxItemHeight = itemHeight;
        
        if (itemWidth > maxItemWidth)
            maxItemWidth = itemWidth;
    }
       
    maxItemWidth  = MAX(maxItemWidth, kMinMenuItemWidth);
    maxItemHeight = MAX(maxItemHeight, kMinMenuItemHeight);

    const CGFloat titleX = kMarginX * 2 + (maxImageWidth > 0 ? maxImageWidth + kMarginX : 0);
    const CGFloat titleWidth = maxItemWidth - titleX - kMarginX * 2;
    
    UIImage *selectedImage = [KxMenuView selectedImage:(CGSize){maxItemWidth, maxItemHeight + 2}];
    UIImage *gradientLine = [KxMenuView gradientLine: (CGSize){maxItemWidth - kMarginX * 4, 1}];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    contentView.autoresizingMask = UIViewAutoresizingNone;
    contentView.backgroundColor = [UIColor clearColor];
    contentView.opaque = NO;
    
    CGFloat itemY = kMarginY * 2;
    NSUInteger itemNum = 0;
        
    for (KxMenuItem *menuItem in _menuItems) {
                
        const CGRect itemFrame = (CGRect){0, itemY, maxItemWidth, maxItemHeight};
        
        UIView *itemView = [[UIView alloc] initWithFrame:itemFrame];
        itemView.autoresizingMask = UIViewAutoresizingNone;
        itemView.backgroundColor = [UIColor clearColor];        
        itemView.opaque = NO;
                
        [contentView addSubview:itemView];
        [itemView release];
        
        if (menuItem.enabled) {
        
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = itemNum;
            button.frame = itemView.bounds;
            button.enabled = menuItem.enabled;
            button.backgroundColor = [UIColor clearColor];
            button.opaque = NO;
            button.autoresizingMask = UIViewAutoresizingNone;
            
            [button addTarget:self
                       action:@selector(performAction:)
             forControlEvents:UIControlEventTouchUpInside];
            
            [button setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
            
            [itemView addSubview:button];
        }
        
        if (menuItem.title.length) {
            
            CGRect titleFrame;
            
            if (!menuItem.enabled && !menuItem.image) {
                
                titleFrame = (CGRect){
                    kMarginX * 2,
                    kMarginY,
                    maxItemWidth - kMarginX * 4,
                    maxItemHeight - kMarginY * 2
                };
                
            } else {
                
                titleFrame = (CGRect){
                    titleX,
                    kMarginY,
                    titleWidth,
                    maxItemHeight - kMarginY * 2
                };
            }
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
            titleLabel.text = menuItem.title;
            titleLabel.font = titleFont;
            titleLabel.textAlignment = menuItem.alignment;
            titleLabel.textColor = menuItem.foreColor ? menuItem.foreColor : [UIColor whiteColor];
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.autoresizingMask = UIViewAutoresizingNone;
            //titleLabel.backgroundColor = [UIColor greenColor];
            [itemView addSubview:titleLabel];            
            [titleLabel release];
        }
        
        if (menuItem.image) {
            
            const CGRect imageFrame = {kMarginX * 2, kMarginY, maxImageWidth, maxItemHeight - kMarginY * 2};
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageFrame];
            imageView.image = menuItem.image;
            imageView.clipsToBounds = YES;
            imageView.contentMode = UIViewContentModeCenter;
            imageView.autoresizingMask = UIViewAutoresizingNone;
            [itemView addSubview:imageView];
            [imageView release];
        }
        
        if (itemNum < _menuItems.count - 1) {
            
            UIImageView *gradientView = [[UIImageView alloc] initWithImage:gradientLine];
            gradientView.frame = (CGRect){kMarginX * 2, maxItemHeight + 1, gradientLine.size};
            gradientView.contentMode = UIViewContentModeLeft;
            [itemView addSubview:gradientView];
            [gradientView release];
            
            itemY += 2;
        }
        
        itemY += maxItemHeight;
        ++itemNum;
    }    
    
    contentView.frame = (CGRect){0, 0, maxItemWidth, itemY + kMarginY * 2};
    
    return [contentView autorelease];
}

+ (UIImage *) selectedImage: (CGSize) size
{
    const CGFloat locations[] = {0,1};
    const CGFloat components[] = {
        0.216, 0.471, 0.871, 1,
        0.059, 0.353, 0.839, 1,
    };
    
    return [self gradientImageWithSize:size locations:locations components:components count:2];
}

+ (UIImage *) gradientLine: (CGSize) size
{
    const CGFloat locations[5] = {0,0.2,0.5,0.8,1};
    
    const CGFloat R = 0.44f, G = 0.44f, B = 0.44f;
        
    const CGFloat components[20] = {
        R,G,B,0.1,
        R,G,B,0.4,
        R,G,B,0.7,
        R,G,B,0.4,
        R,G,B,0.1
    };
    
    return [self gradientImageWithSize:size locations:locations components:components count:5];
}

+ (UIImage *) gradientImageWithSize:(CGSize) size
                          locations:(const CGFloat []) locations
                         components:(const CGFloat []) components
                              count:(NSUInteger)count
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef colorGradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawLinearGradient(context, colorGradient, (CGPoint){0, 0}, (CGPoint){size.width, 0}, 0);
    CGGradientRelease(colorGradient);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void) drawRect:(CGRect)rect
{
    if ([_owner respondsToSelector:@selector(drawBackgroundWithSize:inContext:withArrowDirection:andPosition:)]) {
        
        [_owner drawBackgroundWithSize:self.bounds.size
                             inContext:UIGraphicsGetCurrentContext()
                    withArrowDirection:_arrowDirection
                           andPosition:_arrowPosition];
        
    } else {
        
        [self drawBackground:self.bounds
                   inContext:UIGraphicsGetCurrentContext()];
        
    }
}

- (void)drawBackground:(CGRect)frame
             inContext:(CGContextRef) context
{
    CGFloat R0 = 0.267, G0 = 0.303, B0 = 0.335;
    CGFloat R1 = 0.040, G1 = 0.040, B1 = 0.040;
    
    UIColor *tintColor = [KxMenu tintColor];
    if (tintColor) {
        
        CGFloat a;
        [tintColor getRed:&R0 green:&G0 blue:&B0 alpha:&a];
    }
    
    CGFloat X0 = frame.origin.x;
    CGFloat X1 = frame.origin.x + frame.size.width;
    CGFloat Y0 = frame.origin.y;
    CGFloat Y1 = frame.origin.y + frame.size.height;
    
    // render arrow
    
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    
    // fix the issue with gap of arrow's base if on the edge
    const CGFloat kEmbedFix = 3.f;
    
    if (_arrowDirection == KxMenuViewArrowDirectionUp) {
        
        const CGFloat arrowXM = _arrowPosition;
        const CGFloat arrowX0 = arrowXM - kArrowSize;
        const CGFloat arrowX1 = arrowXM + kArrowSize;
        const CGFloat arrowY0 = Y0;
        const CGFloat arrowY1 = Y0 + kArrowSize + kEmbedFix;
        
        [arrowPath moveToPoint:    (CGPoint){arrowXM, arrowY0}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY1}];
        [arrowPath addLineToPoint: (CGPoint){arrowX0, arrowY1}];
        [arrowPath addLineToPoint: (CGPoint){arrowXM, arrowY0}];
        
        [[UIColor colorWithRed:R0 green:G0 blue:B0 alpha:1] set];
        
        Y0 += kArrowSize;
        
    } else if (_arrowDirection == KxMenuViewArrowDirectionDown) {
        
        const CGFloat arrowXM = _arrowPosition;
        const CGFloat arrowX0 = arrowXM - kArrowSize;
        const CGFloat arrowX1 = arrowXM + kArrowSize;
        const CGFloat arrowY0 = Y1 - kArrowSize - kEmbedFix;
        const CGFloat arrowY1 = Y1;
        
        [arrowPath moveToPoint:    (CGPoint){arrowXM, arrowY1}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY0}];
        [arrowPath addLineToPoint: (CGPoint){arrowX0, arrowY0}];
        [arrowPath addLineToPoint: (CGPoint){arrowXM, arrowY1}];
        
        [[UIColor colorWithRed:R1 green:G1 blue:B1 alpha:1] set];
        
        Y1 -= kArrowSize;
        
    } else if (_arrowDirection == KxMenuViewArrowDirectionLeft) {
        
        const CGFloat arrowYM = _arrowPosition;        
        const CGFloat arrowX0 = X0;
        const CGFloat arrowX1 = X0 + kArrowSize + kEmbedFix;
        const CGFloat arrowY0 = arrowYM - kArrowSize;;
        const CGFloat arrowY1 = arrowYM + kArrowSize;
        
        [arrowPath moveToPoint:    (CGPoint){arrowX0, arrowYM}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY0}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY1}];
        [arrowPath addLineToPoint: (CGPoint){arrowX0, arrowYM}];
        
        [[UIColor colorWithRed:R0 green:G0 blue:B0 alpha:1] set];
        
        X0 += kArrowSize;
        
    } else if (_arrowDirection == KxMenuViewArrowDirectionRight) {
        
        const CGFloat arrowYM = _arrowPosition;        
        const CGFloat arrowX0 = X1;
        const CGFloat arrowX1 = X1 - kArrowSize - kEmbedFix;
        const CGFloat arrowY0 = arrowYM - kArrowSize;;
        const CGFloat arrowY1 = arrowYM + kArrowSize;
        
        [arrowPath moveToPoint:    (CGPoint){arrowX0, arrowYM}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY0}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY1}];
        [arrowPath addLineToPoint: (CGPoint){arrowX0, arrowYM}];
        
        [[UIColor colorWithRed:R1 green:G1 blue:B1 alpha:1] set];
        
        X1 -= kArrowSize;
    }
    
    [arrowPath fill];

    // render body
    
    const CGRect bodyFrame = {X0, Y0, X1 - X0, Y1 - Y0};
    
    UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:bodyFrame
                                                          cornerRadius:8];
        
    const CGFloat locations[] = {0, 1};
    const CGFloat components[] = {
        R0, G0, B0, 1,
        R1, G1, B1, 1,
    };
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace,
                                                                 components,
                                                                 locations,
                                                                 sizeof(locations)/sizeof(locations[0]));
    CGColorSpaceRelease(colorSpace);
    
    
    [borderPath addClip];
    
    CGPoint start, end;
    
    if (_arrowDirection == KxMenuViewArrowDirectionLeft ||
        _arrowDirection == KxMenuViewArrowDirectionRight) {
                
        start = (CGPoint){X0, Y0};
        end = (CGPoint){X1, Y0};
        
    } else {
        
        start = (CGPoint){X0, Y0};
        end = (CGPoint){X0, Y1};
    }
    
    CGContextDrawLinearGradient(context, gradient, start, end, 0);
    
    CGGradientRelease(gradient);    
}

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

static KxMenu *gMenu;
static UIColor *gTintColor;
static UIFont *gTitleFont;

@implementation KxMenu {
    
    KxMenuView *_menuView;
    BOOL        _observing;
}

+ (instancetype) sharedMenu
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        gMenu = [[KxMenu alloc] init];
    });
    return gMenu;
}

- (id) init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void) dealloc
{
    if (_observing) {        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    [_menuView release];
    [super ah_dealloc];
}

- (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
          withMenuItems:(NSArray *)menuItems
{
    [self showMenuInView:view fromRect:rect withOrientation:UIInterfaceOrientationPortrait menuItems:menuItems];
}

- (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
        withOrientation:(UIInterfaceOrientation)orientation
              menuItems:(NSArray *)menuItems
{
    NSParameterAssert(view);
    NSParameterAssert(menuItems.count);
    
    if (_menuView) {
        
        [_menuView dismissMenu:NO];
        _menuView = nil;
    }

    if (!_observing) {
    
        _observing = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationWillChange:)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
    }

    
    _menuView = [[KxMenuView alloc] initWithOwner:self];
    [_menuView showMenuInView:view fromRect:rect withOrientation:orientation menuItems:menuItems];    
}

- (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
            withSubview:(UIView *)contentView
{
    [self showMenuInView:view fromRect:rect withOrientation:UIInterfaceOrientationPortrait subview:contentView];
}

- (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
        withOrientation:(UIInterfaceOrientation)orientation
                subview:(UIView *)contentView
{
    NSParameterAssert(view);
    NSParameterAssert(contentView);
    
    if (_menuView) {
        
        [_menuView dismissMenu:NO];
        _menuView = nil;
    }

    if (!_observing) {
    
        _observing = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationWillChange:)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    
    _menuView = [[KxMenuView alloc] initWithOwner:self];
    [_menuView showMenuInView:view fromRect:rect withOrientation:orientation subview:contentView];    
}

- (void) dismissMenu
{
    if (_menuView) {
        
        [_menuView dismissMenu:NO];
        [_menuView release];
        _menuView = nil;
    }
    
    if (_observing) {
        
        _observing = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void) orientationWillChange: (NSNotification *) n
{
    [self dismissMenu];
}

+ (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
          withMenuItems:(NSArray *)menuItems
{
    [[self sharedMenu] showMenuInView:view fromRect:rect withOrientation:UIInterfaceOrientationPortrait menuItems:menuItems];
}

+ (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
        withOrientation:(UIInterfaceOrientation)orientation
              menuItems:(NSArray *)menuItems
{
    [[self sharedMenu] showMenuInView:view fromRect:rect withOrientation:orientation menuItems:menuItems];
}

+ (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
            withSubview:(UIView *)contentView
{
    [[self sharedMenu] showMenuInView:view fromRect:rect withOrientation:UIInterfaceOrientationPortrait subview:contentView];
}

+ (void) showMenuInView:(UIView *)view
               fromRect:(CGRect)rect
        withOrientation:(UIInterfaceOrientation)orientation
                subview:(UIView *)contentView
{
    [[self sharedMenu] showMenuInView:view fromRect:rect withOrientation:orientation subview:contentView];
}

+ (void) dismissMenu
{
    [[self sharedMenu] dismissMenu];
}

+ (UIColor *) tintColor
{
    return gTintColor;
}

+ (void) setTintColor: (UIColor *) tintColor
{
    if (tintColor != gTintColor) {
        gTintColor = tintColor;
    }
}

+ (UIFont *) titleFont
{
    return gTitleFont;
}

+ (void) setTitleFont: (UIFont *) titleFont
{
    if (titleFont != gTitleFont) {
        gTitleFont = titleFont;
    }
}

// for compatibility with old demo code, "menuItems" instead of "withMenuItems"
+ (void) showMenuInView:(UIView *)view fromRect:(CGRect)rect menuItems:(NSArray *)menuItems {
    [[self sharedMenu] showMenuInView:view fromRect:rect withOrientation:UIInterfaceOrientationPortrait menuItems:menuItems];
}

@end
