//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import "NKTFontPickerViewController.h"
#import "NKTTextView.h"

@class NKTPage;

@protocol NKTPageViewControllerDelegate;

typedef enum
{
    NKTPageStylePlain,
    NKTPageStylePlainRuled,
    NKTPageStyleCollegeRuled,
    NKTPageStyleCream,
    NKTPageStyleCreamRuled,
    NKTPageStyleCollegeRuledCream
} NKTPageStyle;

#pragma mark -

// NKTNotebookViewController manages the editing of an NKTPage. It styles its view to provide a visual page style as
// specified in the page parameter.
@interface NKTPageViewController : UIViewController <UISplitViewControllerDelegate,
                                                     NKTTextViewDelegate,
                                                     NKTFontPickerViewControllerDelegate>
{
@private
    // Data
    NKTPage *page_;
    
    // Delegate
    id <NKTPageViewControllerDelegate> delegate_;
    
    // Control
    UIPopoverController *navigationPopoverController_;
    UIPopoverController *fontPopoverController_;
    NKTFontPickerViewController *fontPickerViewController_;
    
    // UI
    NKTTextView *textView_;
    // Styling
    NKTPageStyle pageStyle_;
    // Adornments
    UIView *edgeView_;
    UIView *fakeGapView_;
    UIImageView *capAndEdgeView_;
    UIImageView *edgeShadowView_;
    // Toolbar
    UIToolbar *toolbar_;
    UILabel *titleLabel_;
    UIButton *navigationButton_;
    UIBarButtonItem *navigationButtonItem_;
    KUIToggleButton *boldToggleButton_;
    KUIToggleButton *italicToggleButton_;
    KUIToggleButton *underlineToggleButton_;
    UIButton *fontButton_;
    UIBarButtonItem *fontToolbarItem_;
}

#pragma mark Accessing the Page

@property (nonatomic, retain) NKTPage *page;

#pragma mark Setting the Delegate

@property (nonatomic, assign) id <NKTPageViewControllerDelegate> delegate;

#pragma mark Accessing Views

@property (nonatomic, retain) IBOutlet NKTTextView *textView;
@property (nonatomic, retain) IBOutlet UIView *edgeView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;

#pragma mark Configuring the Page Style

@property (nonatomic) NKTPageStyle pageStyle;

@end

#pragma mark -

// NKTPageViewControllerDelegate is a protocol that allows clients to receive editing related messages from an
// NKTPageViewController.
@protocol NKTPageViewControllerDelegate <NSObject>

@optional

- (void)pageViewController:(NKTPageViewController *)pageViewController textViewDidChange:(NKTTextView *)textView;

@end
