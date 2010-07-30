/*//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    NKTPageViewStylePlain,
    NKTPageViewStylePlainRuled,
    NKTPageViewStyleCreamRuled,
    NKTPageViewStyleCollegeRuled,
} NKTPageViewStyle; 

@interface NKTPageView : UIView {

}

#pragma mark -
#pragma mark Managing Text

@property (nonatomic, readwrite, copy) NSAttributedString *text;

#pragma mark -
#pragma mark Managing Typography

@property (nonatomic, readwrite) UIEdgeInsets textInset;
@property (nonatomic, readwrite) CGFloat lineHeight;

#pragma mark -
#pragma mark Managing the Page Style

- (void)configureWithStyle:(NKTPageViewStyle)style;

@property (nonatomic, readwrite) BOOL horizontalLinesEnabled;
@property (nonatomic, readwrite) CGFloat horizontalLineOffset;
@property (nonatomic, readwrite, retain) UIColor *horizontalLineColor;

@property (nonatomic, readwrite) BOOL verticalMarginEnabled;
@property (nonatomic, readwrite) CGFloat verticalMarginInset;
@property (nonatomic, readwrite, retain) UIColor *verticalMarginColor;

@end
*/