//
//  Copyright Allen Ding 2010. All rights reserved.
//

#import "NKViewController.h"

@implementation NKViewController

@synthesize textView;

#pragma mark -
#pragma mark Keyboard Notifications

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    NSValue *value = [[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardRect = [value CGRectValue];
    keyboardRect = [self.textView convertRect:keyboardRect fromView:self.textView.window];
    
    CGRect resizedFrame = self.textView.frame;
    resizedFrame.size.height -= keyboardRect.size.height;
    self.textView.frame = resizedFrame;
    // UITextView ensures the cursor is visible after setting the frame
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSValue *value = [[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardRect = [value CGRectValue];
    keyboardRect = [self.textView convertRect:keyboardRect fromView:self.textView.window];
    
    CGPoint originalOffset = self.textView.contentOffset;
    CGRect restoredFrame = self.textView.frame;
    restoredFrame.size.height += keyboardRect.size.height;
    self.textView.frame = restoredFrame;
    self.textView.contentOffset = originalOffset;
}

#pragma mark -
#pragma mark View Management

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerForKeyboardNotifications];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.textView = nil;
}

- (void)dealloc {
    [super dealloc];
}

@end
