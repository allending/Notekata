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
    NKTPageStyle pageStyle_;
    BOOL frozen_;
    id <NKTPageViewControllerDelegate> delegate_;
    
    UIPopoverController *notebookPopoverController_;
    UIPopoverController *fontPopoverController_;
    NKTFontPickerViewController *fontPickerViewController_;
    BOOL menuEnabledForSelectedTextRange_;
    BOOL menuDisabledForKeyboard_;
    
    NKTTextView *textView_;
    UIView *creamPaperBackgroundView_;
    UIView *plainPaperBackgroundView_;
    UIView *rightEdgeView_;
    UIImageView *leftEdgeView_;
    UIImageView *leftEdgeShadowView_;
    UIView *frozenOverlayView_;
    
    UIToolbar *toolbar_;
    UIBarButtonItem *notebookItem_;
    UIBarButtonItem *actionItem_;
    UIBarButtonItem *fontItem_;
    UIBarButtonItem *spacerItem_;
    UIBarButtonItem *boldItem_;
    UIBarButtonItem *italicItem_;
    UIBarButtonItem *underlineItem_;
    UILabel *titleLabel_;
    KUIToggleButton *boldToggleButton_;
    KUIToggleButton *italicToggleButton_;
    KUIToggleButton *underlineToggleButton_;
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

#pragma mark Freezing

- (void)freeze;
- (void)unfreeze;

#pragma mark Navigation

- (void)dismissNotebookPopoverAnimated:(BOOL)animated;

#pragma mark View Controllers

@property (nonatomic, retain) UIPopoverController *fontPopoverController;
@property (nonatomic, retain) NKTFontPickerViewController *fontPickerViewController;

#pragma mark Actions

- (IBAction)notebookItemTapped:(id)sender;
- (IBAction)actionItemTapped:(id)sender;
- (IBAction)fontItemTapped:(id)sender;
- (IBAction)boldItemTapped:(id)sender;
- (IBAction)italicItemTapped:(id)sender;
- (IBAction)underlineItemTapped:(id)sender;

#pragma mark Views

@property (nonatomic, retain) IBOutlet NKTTextView *textView;
@property (nonatomic, retain) UIView *creamPaperBackgroundView;
@property (nonatomic, retain) UIView *plainPaperBackgroundView;
@property (nonatomic, retain) IBOutlet UIView *rightEdgeView;
@property (nonatomic, retain) UIImageView *leftEdgeView;
@property (nonatomic, retain) UIImageView *edgeShadowView;
@property (nonatomic, retain) UIView *frozenOverlayView;

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *notebookItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *actionItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *spacerItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *fontItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *boldItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *italicItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *underlineItem;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) KUIToggleButton *boldToggleButton;
@property (nonatomic, retain) KUIToggleButton *italicToggleButton;
@property (nonatomic, retain) KUIToggleButton *underlineToggleButton;

#pragma mark Updating Views

- (void)configureForNonNilPageAnimated:(BOOL)animated;
- (void)configureForNilPageAnimated:(BOOL)animated;
- (void)updateToolbarAnimated:(BOOL)animated;
- (void)updatePageViews;
- (void)updateTextView;
- (void)updateTitleLabel;
- (void)updateNotebookItem;
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

#pragma mark Menu


- (void)presentMenu;
- (void)updateMenuForTemporaryViewChangesEnded;
- (void)dismissMenu;
- (void)updateMenuForTemporaryViewChangesOccuring;

#pragma mark Keyboard

- (void)registerForKeyboardEvents;
- (void)unregisterForKeyboardEvents;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardDidShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (CGRect)keyboardFrameFromNotification:(NSNotification *)notification;
- (BOOL)keyboardFrameFromNotificationOverlapsTextView:(NSNotification *)notification;
- (void)growTextViewToAccomodateKeyboardFrameFromNotification:(NSNotification *)notification;
- (void)shrinkTextViewToAccomodateKeyboardFrameFromNotification:(NSNotification *)notification;

@end

// NKTPageViewControllerDelegate is a protocol that allows clients to receive editing related messages from an
// NKTPageViewController.
@protocol NKTPageViewControllerDelegate <NSObject>

@optional

- (void)pageViewController:(NKTPageViewController *)pageViewController textViewDidChange:(NKTTextView *)textView;

@end
