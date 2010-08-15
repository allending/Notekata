//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKTTextView : UIScrollView {
@private
    NSAttributedString *text;
    
    UIEdgeInsets margins;
    CGFloat lineHeight;
    
    BOOL horizontalLinesEnabled;
    UIColor *horizontalLineColor;
    CGFloat horizontalLineOffset;
    
    BOOL verticalMarginEnabled;
    UIColor *verticalMarginColor;
    CGFloat verticalMarginInset;
    
    NSMutableArray *typesettedLines;
    
    NSMutableSet *visibleSections;
    NSMutableSet *reusableSections;
}

#pragma mark -
#pragma mark Accessing the Text

@property (nonatomic, readwrite, copy) NSAttributedString *text;

#pragma mark -
#pragma mark Configuring Text Layout

@property (nonatomic, readwrite) UIEdgeInsets margins;
@property (nonatomic, readwrite) CGFloat lineHeight;

#pragma mark -
#pragma mark Configuring Page Markings

@property (nonatomic, readwrite) BOOL horizontalLinesEnabled;
@property (nonatomic, readwrite, retain) UIColor *horizontalLineColor;
@property (nonatomic, readwrite) CGFloat horizontalLineOffset;

@property (nonatomic, readwrite) BOOL verticalMarginEnabled;
@property (nonatomic, readwrite, retain) UIColor *verticalMarginColor;
@property (nonatomic, readwrite) CGFloat verticalMarginInset;

@end
