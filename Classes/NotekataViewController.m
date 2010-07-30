//
//  Copyright Allen Ding 2010. All rights reserved.
//

#import "NotekataViewController.h"
#import <CoreText/CoreText.h>
#import "NKTPageView.h"
#import "NKTTextView.h"

static NSString * const TestText =
    @"The Expedition\n"
     "TODO\n"
     "- Get Supplies\n"
     "- Book travel\n"
     "- Call Stacy\n"
     "\n"
     "Staying Safe\n"
     "- Torches\n"
     "- Blankets\n"
     "\n"
     "The expedition to the depths of the Congo will challenge even the most accomplished of explorers. Limited communication with the outside world makes preparation paramount. Dangerous wildlife lurk in the shadows at every corner.\n"
     "\n"
     "Some chinese characters: 你好。 认识你我很高兴。\n"
     "\n"
     "The Kremlin identified them as Igor V. Sutyagin, an arms control researcher held for 11 years; Sergei Skripal, a colonel in Russia’s military intelligence service sentenced in 2006 to 13 years for spying for Britain; Aleksandr Zaporozhsky, a former agent with Russia’s Foreign Intelligence Service who has served seven years of an 18-year sentence;and Gennadi Vasilenko, a former K.G.B. major who was arrested in 1998 for contacts with a C.I.A. officer but eventually released only to be arrested again in 2005 and later convicted on illegal weapons charges.\n"
     "\n"
     "Within hours of the New York court hearing, the gHULLAgyqBalloo Kremlin announced that President Dmitri A. Medvedev had signed pardons for the four men Russia considered spies after each of them signed statements admitting guilt.\n"
     "\n"
     "Drugs, including heroin and a methamphetamine lab, were discovered in the barracks, as was a homemade sex tape that had been circulating among soldiers and that featured one of the brigade’s female lieutenants and five male sergeants.\n"
     "\n"
     "“Being back in garrison is what we don’t do well, because since 9/11 it seems we’ve spent more time deployed than at home,” Lt. Col. David Wilson said.\n"
     "\n"
     "As the United States military continues to reduce the number of troops in Iraq — to 50,000 by Sept. 1 from about 85,000 now — it has begun to shift some focus to the home front in an effort to ensure a smooth transition for soldiers, a move prompted by lessons learned from returning veterans who have struggled to adjust to lives away from war. Leaders of the Fourth Brigade said its problems had not only been deeply embarrassing, but had revealed institutional ignorance about combat stress and traumatic brain injury that forced the unit to use a holistic approach not typically associated with the military as it confronted its issues.\n"
     "\n"
     "“They were leaving a war zone, coming back home and not getting the care and supervision necessary, which allowed them to stay in the Mosul mind-set,” said Sergeant Major Mustafa, referring to the violent northern Iraq city where the brigade had been stationed before it returned to Fort Bliss in 2008. “This is a group of people that had been fighting and killing and taking casualties for 14 months. You can’t switch it on and off.”\n";

@implementation NotekataViewController

@synthesize textView;
@synthesize coverView;
@synthesize toolbar;

- (NSMutableAttributedString *)testText {
    CTFontRef helvetica = CTFontCreateWithName(CFSTR("Helvetica"), 16.0, nil);
    CGColorRef color = [UIColor blackColor].CGColor;
    NSDictionary *baseAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (id)helvetica, kCTFontAttributeName,
                                    (id)color, kCTForegroundColorAttributeName, nil];
    NSMutableAttributedString *theText = [[NSMutableAttributedString alloc] initWithString:TestText attributes:baseAttributes];
    
    CTFontRef helveticaBoldItalic = CTFontCreateCopyWithSymbolicTraits(helvetica,
                                                                       16.0,
                                                                       NULL,
                                                                       kCTFontItalicTrait|kCTFontBoldTrait,
                                                                       kCTFontItalicTrait|kCTFontBoldTrait);
    NSDictionary *boldItalicAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          (id)helveticaBoldItalic, kCTFontAttributeName, nil];
    [theText setAttributes:boldItalicAttributes range:[[theText string] rangeOfString:@"accomplished of explorers"]];
    
    NSDictionary *underlinedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          (id)helvetica, kCTFontAttributeName,
                                          [NSNumber numberWithInt:kCTUnderlineStyleSingle], kCTUnderlineStyleAttributeName, nil];
    [theText setAttributes:underlinedAttributes range:[[theText string] rangeOfString:@"Stacy"]];
    
//    CTFontRef helveticaBold = CTFontCreateWithName(CFSTR("Helvetica-Bold"), 48.0, nil);
    CTFontRef helveticaBold = CTFontCreateWithName(CFSTR("Helvetica-Bold"), 32.0, nil);
    NSDictionary *boldAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (id)helveticaBold, kCTFontAttributeName,
                                    (id)color, kCTForegroundColorAttributeName, nil];
    [theText setAttributes:boldAttributes range:[[theText string] rangeOfString:@"The Expedition"]];
    
    CTFontRef markerFelt = CTFontCreateWithName(CFSTR("Marker Felt"), 24.0, nil);
    NSDictionary *headingAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                       (id)markerFelt, kCTFontAttributeName,
                                       (id)color, kCTForegroundColorAttributeName, nil];
    [theText setAttributes:headingAttributes range:[[theText string] rangeOfString:@"TODO"]];
    [theText setAttributes:headingAttributes range:[[theText string] rangeOfString:@"Staying Safe"]];
    
    CTFontRef zapfino = CTFontCreateWithName(CFSTR("Zapfino"), 24.0, nil);
    NSDictionary *randomAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                       (id)zapfino, kCTFontAttributeName,
                                       (id)color, kCTForegroundColorAttributeName, nil];
    [theText setAttributes:randomAttributes range:[[theText string] rangeOfString:@"gHULLAgyqBalloo"]];
    
    return [theText autorelease];
}

- (void)useDefaultMargins {
    self.textView.margins = UIEdgeInsetsMake(60.0, 40.0, 40.0, 80.0);
}
 
- (void)useLargeMargins {
    self.textView.margins = UIEdgeInsetsMake(300.0, 200.0, 300.0, 200.0);
}
 
- (void)useDefaultLineHeight {
    self.textView.lineHeight = 24.0;
}

- (void)useLargeLineHeight {
    self.textView.lineHeight = 48.0;
}

- (void)reduceFrameWidth {
    CGRect frame = self.textView.frame;
    frame.size.width -= 100.0;
    self.textView.frame = frame;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageNamed:@"RedCoverPattern.png"];
    self.coverView.backgroundColor = [UIColor colorWithPatternImage:image];

    NSMutableAttributedString *text = [self testText];
    self.textView.text = text;

    UIBarButtonItem *defaultMargins = [[UIBarButtonItem alloc] initWithTitle:@"Default Margins"
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(useDefaultMargins)];
    UIBarButtonItem *largeMargins = [[UIBarButtonItem alloc] initWithTitle:@"Large Margins"
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(useLargeMargins)];
    UIBarButtonItem *defaultLineHeight = [[UIBarButtonItem alloc] initWithTitle:@"Default Line Height"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(useDefaultLineHeight)];
    UIBarButtonItem *largeLineHeight = [[UIBarButtonItem alloc] initWithTitle:@"Large Line Height"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(useLargeLineHeight)];
    UIBarButtonItem *reduceFrameWidth = [[UIBarButtonItem alloc] initWithTitle:@"Reduce Frame Width"
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(reduceFrameWidth)];
    NSArray *items = [NSArray arrayWithObjects:defaultMargins, largeMargins, defaultLineHeight, largeLineHeight, reduceFrameWidth, nil];
    self.toolbar.items = items;
    
    [defaultMargins release];
    [largeMargins release];
    [defaultLineHeight release];
    [largeLineHeight release];
    [reduceFrameWidth release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    self.textView = nil;
}

- (void)dealloc {
    [textView release];
    [coverView release];
    [toolbar release];
    [super dealloc];
}

@end
