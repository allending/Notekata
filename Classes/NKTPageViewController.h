//
// Copyright 2010 Allen Ding. All rights reserved.
//

#import "KobaUI.h"
#import <MessageUI/MessageUI.h>
#import "NKTFontPickerViewController.h"
#import "NKTTextView.h"

@class NKTPage;

@protocol NKTPageViewControllerDelegate;

// NKTPageViewController manages the editing of an NKTPage. It styles its view as specified the
// notebook style of the page's notebook.
@interface NKTPageViewController : UIViewController <
    UIActionSheetDelegate,
    UISplitViewControllerDelegate,
    UIPopoverControllerDelegate,
    MFMailComposeViewControllerDelegate,
    NKTTextViewDelegate,
    NKTFontPickerViewControllerDelegate>
{
@private
    NKTPage *page_;
    BOOL frozen_;
    NSUInteger changeCountSinceSave_;
    NSUInteger textLengthBeforeChange_;
    NSUInteger totalTextLengthChangeSinceSave_;
    NSUndoManager *undoManager_;
    BOOL allowUndoCheckpoint_;
    
    id <NKTPageViewControllerDelegate> delegate_;
    UIPopoverController *notebookPopoverController_;
    BOOL notebookPopoverHidden_;
    UIPopoverController *fontPopoverController_;
    NKTFontPickerViewController *fontPickerViewController_;
    BOOL menuEnabledForSelectedTextRange_;
    BOOL menuDisabledForKeyboard_;
    UIActionSheet *mailActionSheet_;
    
    NKTTextView *textView_;
    UIView *creamBackgroundView_;
    UIView *plainBackgroundView_;
    UIView *rightEdgeView_;
    UIImageView *leftEdgeView_;
    UIImageView *leftEdgeShadowView_;
    UIView *frozenOverlayView_;
    // Toolbar
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

#pragma mark -
#pragma mark Memory

- (void)purgeCachedResources;

#pragma mark -
#pragma mark Page

// Setting a new page causes any pending changes to be saved.
@property (nonatomic, retain) NKTPage *page;

- (void)enterSaveCheckpoint;
- (void)savePendingChanges;

#pragma mark -
#pragma mark Undo

- (void)registerUndoForCurrentState;
- (void)applyUndoWithInfo:(NSDictionary *)undoInfo;

#pragma mark -
#pragma mark Delegate

@property (nonatomic, assign) id <NKTPageViewControllerDelegate> delegate;

#pragma mark -
#pragma mark Actions

- (IBAction)notebookItemTapped:(id)sender;
- (IBAction)actionItemTapped:(id)sender;
- (IBAction)fontItemTapped:(id)sender;
- (IBAction)boldItemTapped:(id)sender;
- (IBAction)italicItemTapped:(id)sender;
- (IBAction)underlineItemTapped:(id)sender;

#pragma mark -
#pragma mark Freezing

- (BOOL)isNotebookPopoverInSafeState;
- (void)freeze;
- (void)unfreeze;

#pragma mark -
#pragma mark Notebook Popover

- (void)dismissNotebookPopoverAnimated:(BOOL)animated;

#pragma mark -
#pragma mark Updating Views

- (void)configureViewsForNonNilPageAnimated:(BOOL)animated;
- (void)configureViewsForNilPageAnimated:(BOOL)animated;
- (void)applyNotebookStyle;
- (void)updateToolbarAnimated:(BOOL)animated;
- (void)updatePageDependentViews;
- (void)updateTextView;
- (void)updateTitleLabel;
- (void)updateNotebookItem;
- (void)updateTextEditingItems;

#pragma mark -
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

#pragma mark -
#pragma mark Menu

- (void)presentMenu;
- (void)dismissMenu;
- (void)updateMenuForTemporaryViewChangesOccuring;
- (void)updateMenuForTemporaryViewChangesEnded;

#pragma mark -
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

#pragma mark -
#pragma mark View Controllers

@property (nonatomic, retain) UIPopoverController *fontPopoverController;
@property (nonatomic, retain) NKTFontPickerViewController *fontPickerViewController;

#pragma mark -
#pragma mark Views

@property (nonatomic, retain) IBOutlet NKTTextView *textView;
@property (nonatomic, retain) UIView *creamBackgroundView;
@property (nonatomic, retain) UIView *plainBackgroundView;
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

@end

// NKTPageViewControllerDelegate
@protocol NKTPageViewControllerDelegate <NSObject>

@optional

- (void)pageViewController:(NKTPageViewController *)pageViewController textView:(NKTTextView *)textView didChangeFromTextPosition:(NKTTextPosition *)textPosition;

@end
