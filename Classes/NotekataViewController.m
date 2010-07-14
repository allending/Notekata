//
//  Copyright Allen Ding 2010. All rights reserved.
//

#import "NotekataViewController.h"
#import <CoreText/CoreText.h>
#import "NKTPageView.h"

static NSString * const TestText =
    @"My Expedition\n"
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
     "Within hours of the New York court hearing, the HULLAgyqBalloo Kremlin announced that President Dmitri A. Medvedev had signed pardons for the four men Russia considered spies after each of them signed statements admitting guilt.\n";

@implementation NotekataViewController

@synthesize pageView;
@synthesize coverView;

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
    
    CTFontRef helveticaBold = CTFontCreateWithName(CFSTR("Helvetica-Bold"), 32.0, nil);
    NSDictionary *boldAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (id)helveticaBold, kCTFontAttributeName,
                                    (id)color, kCTForegroundColorAttributeName, nil];
    [theText setAttributes:boldAttributes range:[[theText string] rangeOfString:@"My Expedition"]];
    
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
    [theText setAttributes:randomAttributes range:[[theText string] rangeOfString:@"HULLAgyqBalloo"]];
    
    return [theText autorelease];
}

- (IBAction)performAction1 {
    [self.pageView configureWithStyle:NKTPageViewStylePlain];
}

- (IBAction)performAction2 {
    [self.pageView configureWithStyle:NKTPageViewStylePlainRuled];
}

- (IBAction)performAction3 {
    [self.pageView configureWithStyle:NKTPageViewStyleCreamRuled];
}

- (IBAction)performAction4 {
    [self.pageView configureWithStyle:NKTPageViewStyleCollegeRuled];
}

- (void)viewDidLoad {
    UIImage *image = [UIImage imageNamed:@"RedCoverPattern.png"];
    self.coverView.backgroundColor = [UIColor colorWithPatternImage:image];
    
    [self.pageView configureWithStyle:NKTPageViewStyleCreamRuled];
    self.pageView.lineHeight = 32.0;
    NSMutableAttributedString *text = [self testText];
    self.pageView.text = text;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    self.pageView = nil;
}

- (void)dealloc {
    [super dealloc];
}

@end
