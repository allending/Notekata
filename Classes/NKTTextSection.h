//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKTTextSection : UIView {
@private
    NSInteger index;
    
    NSArray *typesettedLines;
    
    UIEdgeInsets margins;
    CGFloat lineHeight;
    NSUInteger numberOfSkirtLines;

    BOOL horizontalLinesEnabled;
    UIColor *horizontalLineColor;
    CGFloat horizontalLineOffset;
}

#pragma mark -
#pragma mark Accessing the Index

@property (nonatomic, readwrite) NSInteger index;

#pragma mark -
#pragma mark Accessing the Typesetted Lines

@property (nonatomic, readwrite, retain) NSArray *typesettedLines;

#pragma mark -
#pragma mark Configuring Text Layout

@property (nonatomic, readwrite) UIEdgeInsets margins;
@property (nonatomic, readwrite) CGFloat lineHeight;
@property (nonatomic, readwrite) NSUInteger numberOfSkirtLines;

#pragma mark -
#pragma mark Configuring Page Markings

@property (nonatomic, readwrite) BOOL horizontalLinesEnabled;
@property (nonatomic, readwrite, retain) UIColor *horizontalLineColor;
@property (nonatomic, readwrite) CGFloat horizontalLineOffset;

@end
