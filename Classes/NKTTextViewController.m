//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import "NKTTextViewController.h"
#import "KobaText.h"

@interface NKTTextViewController()

#pragma mark Managing Views

@property (nonatomic, retain) KUIToggleButton *boldToggleButton;
@property (nonatomic, retain) KUIToggleButton *italicToggleButton;
@property (nonatomic, retain) KUIToggleButton *underlineToggleButton;

- (void)createToolbarItems;

#pragma mark Managing Text Attributes

- (NSDictionary *)activeTextAttributes;

#pragma mark Responding to Actions

- (void)boldToggleChanged:(KUIToggleButton *)toggleButton;
- (void)italicToggleChanged:(KUIToggleButton *)toggleButton;
- (void)underlineToggleChanged:(KUIToggleButton *)toggleButton;

@end

#pragma mark -

//--------------------------------------------------------------------------------------------------

@implementation NKTTextViewController

@synthesize toolbar = toolbar_;
@synthesize edgeView = edgeView_;
@synthesize textView = textView_;
@synthesize boldToggleButton = boldToggleButton_;
@synthesize italicToggleButton = italicToggleButton_;
@synthesize underlineToggleButton = underlineToggleButton_;

//--------------------------------------------------------------------------------------------------

#pragma mark Initializing

- (void)dealloc
{
    [toolbar_ release];
    [edgeView_ release];
    [textView_ release];
    [boldToggleButton_ release];
    [italicToggleButton_ release];
    [underlineToggleButton_ release];
    [super dealloc];
}
//--------------------------------------------------------------------------------------------------

#pragma mark Managing Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.toolbar = nil;
    self.edgeView = nil;
    self.textView = nil;
    self.boldToggleButton = nil;
    self.italicToggleButton = nil;
    self.underlineToggleButton = nil;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Views

- (UIColor *)loupeFillColor
{
    return self.view.backgroundColor;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    UIImage *edgePattern = [UIImage imageNamed:@"RedCoverPattern.png"];
    self.edgeView.backgroundColor = [UIColor colorWithPatternImage:edgePattern];
    
    UIImage *backgroundPattern = [UIImage imageNamed:@"CreamPaperPattern.png"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:backgroundPattern];
    
    [self createToolbarItems];
    
    textView_.delegate = self;
    textView_.activeTextAttributes = [self activeTextAttributes];
}

- (void)createToolbarItems
{
    boldToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [boldToggleButton_ addTarget:self action:@selector(boldToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [boldToggleButton_ setTitle:@"B" forState:UIControlStateNormal];
    boldToggleButton_.titleLabel.font = [UIFont fontWithName:@"Georgia-Bold" size:16.0];
    boldToggleButton_.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    
    italicToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [italicToggleButton_ addTarget:self action:@selector(italicToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [italicToggleButton_ setTitle:@"I" forState:UIControlStateNormal];
    italicToggleButton_.titleLabel.font = [UIFont fontWithName:@"Georgia-Italic" size:16.0];
    italicToggleButton_.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    
    underlineToggleButton_ = [[KUIToggleButton alloc] initWithStyle:KUIToggleButtonStyleTextDark];
    [underlineToggleButton_ addTarget:self action:@selector(underlineToggleChanged:) forControlEvents:UIControlEventValueChanged];
    [underlineToggleButton_ setTitle:@"U" forState:UIControlStateNormal];
    underlineToggleButton_.titleLabel.font = [UIFont fontWithName:@"Georgia-Bold" size:16.0];
    underlineToggleButton_.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    
    UIBarButtonItem *boldToggleItem = [[UIBarButtonItem alloc] initWithCustomView:boldToggleButton_];
    UIBarButtonItem *italicToggleItem = [[UIBarButtonItem alloc] initWithCustomView:italicToggleButton_];
    UIBarButtonItem *underlineToggleItem = [[UIBarButtonItem alloc] initWithCustomView:underlineToggleButton_];
    self.toolbar.items = [NSArray arrayWithObjects:boldToggleItem, italicToggleItem, underlineToggleItem, nil];
    [boldToggleItem release];
    [italicToggleItem release];
    [underlineToggleItem release];
}

//--------------------------------------------------------------------------------------------------

#pragma mark Configuring the View Rotation Settings

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

//--------------------------------------------------------------------------------------------------

#pragma mark Managing Text Attributes

- (NSDictionary *)activeTextAttributes
{
    KBTFontGenerator *fontGenerator = [KBTFontGenerator fontGenerator];
    fontGenerator.fontFamily = @"Marker Felt";
    fontGenerator.fontSize = 16.0;
    
    if (boldToggleButton_.isSelected)
    {
        fontGenerator.boldTraitEnabled = YES;
    }
    
    if (italicToggleButton_.isSelected)
    {
        fontGenerator.italicTraitEnabled = YES;
    }
    
    KBTTextStyleGenerator *textStyleGenerator = [KBTTextStyleGenerator textStyleGenerator];
    textStyleGenerator.font = [fontGenerator bestFont];
    textStyleGenerator.underlined = underlineToggleButton_.isSelected;
    return [textStyleGenerator textAttributes];

/*
    //CTFontRef baseFont = CTFontCreateWithName(CFSTR("Helvetica"), 14.0, nil);
    NSDictionary *fontTraitAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:fontSymbolicTraits] forKey:(id)kCTFontSymbolicTrait];
    NSDictionary *fontAttributes = [NSDictionary dictionaryWithObjectsAndKeys:fontTraitAttributes, (id)kCTFontTraitsAttribute,
//                                                                              @"Marker Felt", (id)kCTFontFamilyNameAttribute,
//                                                                              @"Marker Felt", (id)kCTFontNameAttribute,
                                                                              nil];
    CTFontDescriptorRef baseDescriptor = CTFontDescriptorCreateWithNameAndSize((CFStringRef)@"Marker Felt", 16.0);
    CTFontDescriptorRef fontDescriptor = CTFontDescriptorCreateCopyWithAttributes(baseDescriptor, (CFDictionaryRef)fontAttributes);
    
    NSString *check = (id)CTFontDescriptorCopyAttribute(fontDescriptor, kCTFontFamilyNameAttribute);
    KBCLogDebug(@"backcheck: %@", check);
    
//    CTFontDescriptorRef fontDescriptor = CTFontDescriptorCreateWithAttributes((CFDictionaryRef)fontAttributes);
    CTFontRef font = CTFontCreateWithFontDescriptor(fontDescriptor, 16.0, NULL);
    CTUnderlineStyle underlineStyle = underlineToggleButton_.isSelected ? kCTUnderlineStyleSingle : kCTUnderlineStyleNone;
    NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:(id)font, (id)kCTFontAttributeName,
                                                                              [NSNumber numberWithInt:underlineStyle], (id)kCTUnderlineStyleAttributeName, nil];
    //CFRelease(baseFont);
    CFRelease(font);
    return textAttributes;
*/
}

//--------------------------------------------------------------------------------------------------

#pragma mark Responding to Actions

- (void)boldToggleChanged:(KUIToggleButton *)toggleButton
{
    // change the attributes of currently selected text?
    
    // change the attributes of insertion text?
    textView_.activeTextAttributes = [self activeTextAttributes];
}

- (void)italicToggleChanged:(KUIToggleButton *)toggleButton
{
    textView_.activeTextAttributes = [self activeTextAttributes];   
}

- (void)underlineToggleChanged:(KUIToggleButton *)toggleButton
{
    textView_.activeTextAttributes = [self activeTextAttributes];
}

@end

/*
 - (void)setPlainStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalRulesEnabled = NO;
    self.paperView.verticalMarginEnabled = NO;
}

- (void)setPlainRuledStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalRulesEnabled = YES;
    self.paperView.horizontalRuleColor = [UIColor colorWithRed:0.77 green:0.77 blue:0.72 alpha:1.0];
    self.paperView.verticalMarginEnabled = NO;
}

- (void)setCreamRuledStyle {
    UIImage *image = [UIImage imageNamed:@"CreamPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalRulesEnabled = YES;
    self.paperView.horizontalRuleColor = [UIColor colorWithRed:0.72 green:0.72 blue:0.59 alpha:1.0];
    self.paperView.verticalMarginEnabled = NO;
}

- (void)setCollegeRuledStyle {
    UIImage *image = [UIImage imageNamed:@"PlainPaperPattern.png"];
    self.paperView.backgroundColor = [UIColor colorWithPatternImage:image];
    self.paperView.horizontalRulesEnabled = YES;
    self.paperView.horizontalRuleColor = [UIColor colorWithRed:0.69 green:0.77 blue:0.9 alpha:1.0];
    self.paperView.verticalMarginEnabled = YES;
    self.paperView.verticalMarginColor = [UIColor colorWithRed:0.83 green:0.3 blue:0.29 alpha:1.0];
    self.paperView.verticalMarginInset = 60.0;
}
 */
