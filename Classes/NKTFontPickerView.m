//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTFontPickerView.h"

@implementation NKTFontPickerView

@synthesize fontSizeSegmentedControl = fontSizeSegmentedControl_;
@synthesize fontFamilyTableView = fontFamilyTableView_;

static NSString * const TableViewTopCapFilename = @"NKTFontPickerViewTableViewTopCap.png";
static NSString * const TableViewBottomCapFilename = @"NKTFontPickerViewTableViewBottomCap.png";
static NSString * const TableViewBorderFilename = @"NKTFontPickerViewTableViewBorder.png";

static const CGFloat FontSizeSegmentedControlHeight = 44.0;
static const CGFloat TableViewCapWidth = 8.0;
static const CGFloat TableViewCapHeight = 9.0;
static const CGFloat SubviewInset = 20.0;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        lastLayoutFrame_ = CGRectNull;
        
        // Off-gray background color - scheme tied to the table view cap images
        self.backgroundColor = [UIColor colorWithRed:0.82 green:0.83 blue:0.85 alpha:1.0];
        self.opaque = YES;
        self.autoresizesSubviews = NO;
        
        // Create font size segmented control
        NSArray *items = [NSArray arrayWithObjects:@"12 pt", @"16 pt", @"24 pt", @"32 pt", nil];
        fontSizeSegmentedControl_ = [[KUISegmentedControl alloc] initWithItems:items];
        [self addSubview:fontSizeSegmentedControl_];
        
        // Create font family table view
        fontFamilyTableView_ = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
        // Scroll indicator insets so indicators don't collide with table view caps
        fontFamilyTableView_.scrollIndicatorInsets = UIEdgeInsetsMake(TableViewCapHeight, 0.0, TableViewCapHeight, 0.0);
        [self addSubview:fontFamilyTableView_];
        
        // Create top cap
        UIImage *topCapImage = [UIImage imageNamed:TableViewTopCapFilename];
        topCapImage = [topCapImage stretchableImageWithLeftCapWidth:TableViewCapWidth
                                                       topCapHeight:TableViewCapHeight];
        tableViewTopCap_ = [[UIImageView alloc] initWithImage:topCapImage];
        [self addSubview:tableViewTopCap_];
        
        // Create bottom cap
        UIImage *bottomCapImage = [UIImage imageNamed:TableViewBottomCapFilename];
        bottomCapImage = [bottomCapImage stretchableImageWithLeftCapWidth:TableViewCapWidth
                                                             topCapHeight:TableViewCapHeight];
        tableViewBottomCap_ = [[UIImageView alloc] initWithImage:bottomCapImage];
        [self addSubview:tableViewBottomCap_];
        
        UIImage *tableViewBorderImage = [UIImage imageNamed:TableViewBorderFilename];
        
        // Create left edge
        tableViewLeftBorder_ = [[UIImageView alloc] initWithImage:tableViewBorderImage];
        [self addSubview:tableViewLeftBorder_];
        
        // Create right edge
        tableViewRightBorder_ = [[UIImageView alloc] initWithImage:tableViewBorderImage];
        [self addSubview:tableViewRightBorder_];
        
        // Perform initial layout
        [self setNeedsLayout];
    }
    
    return self;
}

- (void)dealloc
{
    [fontSizeSegmentedControl_ release];
    [fontFamilyTableView_ release];
    [tableViewTopCap_ release];
    [tableViewBottomCap_ release];
    [tableViewLeftBorder_ release];
    [tableViewRightBorder_ release];
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Accessing the Font Picker Subviews

- (void)setFontSizeSegmentedControl:(KUISegmentedControl *)fontSizeSegmentedControl
{
    if (fontSizeSegmentedControl_ == fontSizeSegmentedControl)
    {
        return;
    }
    
    [fontSizeSegmentedControl_ removeFromSuperview];
    [fontSizeSegmentedControl_ release];
    fontSizeSegmentedControl_ = [fontSizeSegmentedControl retain];
    [self addSubview:fontSizeSegmentedControl_];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Laying out Views

- (void)layoutSubviews
{
    // For an inexplicable reason, layoutSubviews is called on this object when the table view
    // scrolls, so we explicitly check to see if the frame has changed
    if (CGRectEqualToRect(self.frame, lastLayoutFrame_))
    {
        return;
    }
    
    CGSize size = self.bounds.size;
    CGFloat subviewWidth = size.width - (2.0 * SubviewInset);
    
    // Font size segmented control
    fontSizeSegmentedControl_.frame = CGRectMake(SubviewInset,
                                                 SubviewInset,
                                                 subviewWidth,
                                                 FontSizeSegmentedControlHeight);
    
    [fontSizeSegmentedControl_ layoutSubviews];
    
    // Font family table view
    fontFamilyTableView_.frame = CGRectMake(SubviewInset,
                                            CGRectGetMaxY(fontSizeSegmentedControl_.frame) + SubviewInset,
                                            subviewWidth,
                                            size.height - CGRectGetMaxY(fontSizeSegmentedControl_.frame) - (2.0 * SubviewInset));
    
    // Top cap
    tableViewTopCap_.frame = CGRectMake(SubviewInset,
                                        CGRectGetMinY(fontFamilyTableView_.frame),
                                        subviewWidth,
                                        TableViewCapHeight);
    
    // Bottom cap
    tableViewBottomCap_.frame = CGRectMake(SubviewInset,
                                           CGRectGetMaxY(fontFamilyTableView_.frame) - TableViewCapHeight,
                                           subviewWidth,
                                           TableViewCapHeight);
    
    // Left border
    tableViewLeftBorder_.frame = CGRectMake(SubviewInset,
                                            CGRectGetMaxY(tableViewTopCap_.frame),
                                            1.0,
                                            CGRectGetHeight(fontFamilyTableView_.frame) - (2.0 * TableViewCapHeight));
    
    // Right border
    tableViewRightBorder_.frame = CGRectMake(CGRectGetMaxX(tableViewTopCap_.frame) - 1.0,
                                             CGRectGetMaxY(tableViewTopCap_.frame),
                                             1.0,
                                             CGRectGetHeight(fontFamilyTableView_.frame) - (2.0 * TableViewCapHeight));
    
    lastLayoutFrame_ = self.frame;
}

@end
