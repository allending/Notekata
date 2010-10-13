//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"

@protocol NKTFontPickerViewControllerDelegate;

// NKTFontViewController
@interface NKTFontPickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
    // Data
    NSArray *availableFontSizes_;
    NSUInteger selectedFontSizeIndex_;
    NSArray *fontFamilyNames_;
    NSUInteger selectedFontFamilyNameIndex_;
    
    // Delegate
    id <NKTFontPickerViewControllerDelegate> delegate_;
}

#pragma mark Accessing the Delegate

@property (nonatomic, assign) id <NKTFontPickerViewControllerDelegate> delegate;

#pragma mark Configuring the Font Size

@property (nonatomic, copy) NSArray *availableFontSizes;
@property (nonatomic) NSUInteger selectedFontSize;

#pragma mark Configuring Font Family Names

@property (nonatomic, copy) NSString *selectedFontFamilyName;

@end

#pragma mark -

// NKTFontPickerViewControllerDelegate
@protocol NKTFontPickerViewControllerDelegate <NSObject>

@optional

#pragma mark Responding to Font Changes

- (void)fontPickerViewController:(NKTFontPickerViewController *)fontPickerViewController
         didSelectFontFamilyName:(NSString *)fontFamilyName;
- (void)fontPickerViewController:(NKTFontPickerViewController *)fontPickerViewController
               didSelectFontSize:(CGFloat)fontSize;

@end
