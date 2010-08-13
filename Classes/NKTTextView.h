//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKTTextView : UIScrollView {
@private
    NSAttributedString *text;
    CGFloat lineHeight;
    UIEdgeInsets margins;
    NSMutableArray *typesettedLines;
    
    NSMutableSet *visibleSections;
    NSMutableSet *reusableSections;
}

#pragma mark -
#pragma mark Accessing Text

@property (nonatomic, readwrite, copy) NSAttributedString *text;

#pragma mark -
#pragma mark Configuring Text Layout

@property (nonatomic, readwrite) CGFloat lineHeight;
@property (nonatomic, readwrite) UIEdgeInsets margins;

@end
