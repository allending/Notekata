//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKTRuledSection : UIView {
@private
    NSUInteger index;
    
    BOOL horizontalLinesEnabled;
    CGFloat horizontalLineOffset;
    UIColor *horizontalLineColor;
    CGFloat lineHeight;
    
//    BOOL verticalMarginEnabled;
//    CGFloat verticalMarginInset;
    UIColor *verticalMarginColor;
}

#pragma mark -
#pragma mark Configuring the Section

@property (nonatomic, readwrite) NSUInteger index;

#pragma mark -
#pragma mark Configuring the Paper Style

@property (nonatomic, readwrite) BOOL horizontalLinesEnabled;
@property (nonatomic, readwrite) CGFloat horizontalLineOffset;
@property (nonatomic, readwrite, retain) UIColor *horizontalLineColor;
@property (nonatomic, readwrite) CGFloat lineHeight;
@property (nonatomic, readonly) NSUInteger horizontalLineCount;

//@property (nonatomic, readwrite) BOOL verticalMarginEnabled;
//@property (nonatomic, readwrite) CGFloat verticalMarginInset;
//@property (nonatomic, readwrite, retain) UIColor *verticalMarginColor;

@end
