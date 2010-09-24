//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "KobaUI.h"

@class NKTFontPickerViewController;

//--------------------------------------------------------------------------------------------------
// NKTFontPickerViewControllerDelegate
//--------------------------------------------------------------------------------------------------

@protocol NKTFontPickerViewControllerDelegate <NSObject>

@optional

#pragma mark Responding to Font Changes

- (void)fontPickerViewController:(NKTFontPickerViewController *)fontPickerViewController
               didSelectFontSize:(CGFloat)fontSize;
- (void)fontPickerViewController:(NKTFontPickerViewController *)fontPickerViewController
         didSelectFontFamilyName:(NSString *)fontFamilyName;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------
// NKTFontViewController
//--------------------------------------------------------------------------------------------------

@interface NKTFontPickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
    id <NKTFontPickerViewControllerDelegate> delegate_;
    
    NSArray *availableFontSizes_;
    NSUInteger selectedFontSizeIndex_;
    
    NSArray *fontFamilyNames_;
    NSUInteger selectedFontFamilyNameIndex_;
}

#pragma mark Accessing the Delegate

@property (nonatomic, assign) id <NKTFontPickerViewControllerDelegate> delegate;

#pragma mark Managing the Font Size

@property (nonatomic, copy) NSArray *availableFontSizes;
@property (nonatomic) NSUInteger selectedFontSize;

#pragma mark Setting the Selected Family Name

@property (nonatomic, copy) NSString *selectedFontFamilyName;

@end
