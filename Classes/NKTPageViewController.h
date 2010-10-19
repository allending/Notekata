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

// NKTNotebookViewController manages the editing of an NKTPage. It styles its view to provide a visual page style as
// specified in the page parameter.
@interface NKTPageViewController : UIViewController <UISplitViewControllerDelegate, UIPopoverControllerDelegate, NKTTextViewDelegate, NKTFontPickerViewControllerDelegate>
{
@private
    NKTPage *page_;
    id <NKTPageViewControllerDelegate> delegate_;

    UIPopoverController *navigationPopoverController_;
    UIPopoverController *fontPopoverController_;
    NKTFontPickerViewController *fontPickerViewController_;
    
    NKTTextView *textView_;
    UIView *creamPaperBackgroundView_;
    UIView *plainPaperBackgroundView_;
    NKTPageStyle pageStyle_;
    UIView *coverEdgeView_;
    UIImageView *capAndEdgeView_;
    UIImageView *edgeShadowView_;
    UIToolbar *toolbar_;
    UILabel *titleLabel_;
    UIButton *navigationButton_;
    UIBarButtonItem *navigationButtonItem_;
    KUIToggleButton *boldToggleButton_;
    KUIToggleButton *italicToggleButton_;
    KUIToggleButton *underlineToggleButton_;
    UIButton *fontButton_;
    UIBarButtonItem *fontToolbarItem_;
    UIView *frozenOverlay_;
}

#pragma mark Page

@property (nonatomic, retain) NKTPage *page;

- (void)setPage:(NKTPage *)page;
// PENDING: the page view controller should know when the page goes away, and save on its own
- (void)savePendingChanges;

#pragma mark Delegate

@property (nonatomic, assign) id <NKTPageViewControllerDelegate> delegate;

#pragma mark Styles

@property (nonatomic) NKTPageStyle pageStyle;

- (void)applyPageStyle;

#pragma mark User Interaction

- (void)freezeUserInteraction;
- (void)unfreezeUserInteraction;

#pragma mark Navigation

- (void)dismissNavigationPopoverAnimated:(BOOL)animated;
- (void)handleNavigationButtonTapped:(UIButton *)button;

#pragma mark View Controllers

@property (nonatomic, retain) UIPopoverController *fontPopoverController;
@property (nonatomic, retain) NKTFontPickerViewController *fontPickerViewController;

#pragma mark Views

@property (nonatomic, retain) IBOutlet NKTTextView *textView;
@property (nonatomic, retain) IBOutlet UIView *coverEdgeView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) UIView *creamPaperBackgroundView;
@property (nonatomic, retain) UIView *plainPaperBackgroundView;
@property (nonatomic, retain) UIImageView *capAndEdgeView;
@property (nonatomic, retain) UIImageView *edgeShadowView;
@property (nonatomic, retain) UIView *frozenOverlay;
@property (nonatomic, retain) UIButton *navigationButton;
@property (nonatomic, retain) UIBarButtonItem *navigationButtonItem;
@property (nonatomic, retain) KUIToggleButton *boldToggleButton;
@property (nonatomic, retain) KUIToggleButton *italicToggleButton;
@property (nonatomic, retain) KUIToggleButton *underlineToggleButton;
@property (nonatomic, retain) UIButton *fontButton;
@property (nonatomic, retain) UIBarButtonItem *fontToolbarItem;

- (UIButton *)borderedToolbarButton;
- (void)addToolbarItems;

#pragma mark Updating Views

- (void)updateViews;
- (void)updateTextView;
- (void)updateTitleLabel;
- (void)updateNavigationButtonTitle;
- (void)updateTextEditingItems;

#pragma mark Text Editing

- (NSDictionary *)currentCoreTextAttributes;
- (NSDictionary *)attributesByAddingBoldTraitToAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByRemovingBoldTraitFromAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByAddingItalicTraitToAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByRemovingItalicTraitFromAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByAddingUnderlineToAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesByRemovingUnderlineFromAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesBySettingFontSizeOfAttributes:(NSDictionary *)attributes;
- (NSDictionary *)attributesBySettingFontFamilyNameOfAttributes:(NSDictionary *)attributes;

- (void)handlePageStyleTapped:(UIButton *)button;
- (void)handleFontButtonTapped:(UIButton *)button;
- (void)handleBoldToggleTapped:(KUIToggleButton *)toggleButton;
- (void)handleItalicToggleTapped:(KUIToggleButton *)toggleButton;
- (void)handleUnderlineToggleTapped:(KUIToggleButton *)toggleButton;
- (void)handleFontButtonTapped:(UIButton *)button;

#pragma mark Keyboard

- (void)registerForKeyboardEvents;
- (void)unregisterForKeyboardEvents;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardDidShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (CGRect)keyboardFrameFromNotification:(NSNotification *)notification;
- (void)growTextViewToAccomodateKeyboardFrameFromNotification:(NSNotification *)notification;
- (void)shrinkTextViewToAccomodateKeyboardFrameFromNotification:(NSNotification *)notification;

@end

// NKTPageViewControllerDelegate is a protocol that allows clients to receive editing related messages from an
// NKTPageViewController.
@protocol NKTPageViewControllerDelegate <NSObject>

@optional

- (void)pageViewController:(NKTPageViewController *)pageViewController textViewDidChange:(NKTTextView *)textView;

@end
