//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

@class NKTFontViewController;

//--------------------------------------------------------------------------------------------------
// NKTFontViewControllerDelegate
//--------------------------------------------------------------------------------------------------

@protocol NKTFontViewControllerDelegate <NSObject>

@optional

- (void)fontViewController:(NKTFontViewController *)fontViewController didSelectFamilyName:(NSString *)familyName;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------
// NKTFontViewController
//--------------------------------------------------------------------------------------------------

@interface NKTFontViewController : UITableViewController
{
@private
    id <NKTFontViewControllerDelegate> delegate_;
    NSArray *familyNames_;
    NSUInteger selectionIndex_;
}

#pragma mark Accessing the Delegate

@property (nonatomic, assign) id <NKTFontViewControllerDelegate> delegate;

#pragma mark Setting the Selected Family Name

@property (nonatomic, copy) NSString *selectedFamilyName;

@end
