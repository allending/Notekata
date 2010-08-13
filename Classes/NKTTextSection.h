//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NKTTextSection : UIView {
@private
    NSInteger index;
    NSArray *typesettedLines;
    CGFloat lineHeight;
    UIEdgeInsets margins;
    NSUInteger skirtLineCount;
}

#pragma mark -
#pragma mark Accessing the Index

@property (nonatomic, readwrite) NSInteger index;

#pragma mark -
#pragma mark Configuring the Text Lines

@property (nonatomic, readwrite, retain) NSArray *typesettedLines;
@property (nonatomic, readwrite) CGFloat lineHeight;
@property (nonatomic, readwrite) UIEdgeInsets margins;
@property (nonatomic, readwrite) NSUInteger skirtLineCount;

@end
