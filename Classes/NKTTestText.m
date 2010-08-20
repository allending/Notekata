//
//  Copyright 2010 Allen Ding. All rights reserved.
//

#import "NKTTestText.h"
#import <CoreText/CoreText.h>

static NSString * const TestText =
    @"The Expedition\n"
    "TODO\n"
    "- Get Supplies\n"
    "- Book travel\n"
    "- Call Stacy\n\n"
    "Staying Safe\n"
    "- Torches\n"
    "- Blankets\n\n"
    "The expedition to the depths of the Congo will challenge even the most accomplished of explorers. Limited communication with the outside world makes preparation paramount. Dangerous wildlife lurk in the shadows at every corner.\n\n"
    "Some chinese characters: 你好。 认识你我很高兴。\n\n"
    "The Kremlin identified them as Igor V. Sutyagin, an arms control researcher held for 11 years; Sergei Skripal, a colonel in Russia’s military intelligence service sentenced in 2006 to 13 years for spying for Britain; Aleksandr Zaporozhsky, a former agent with Russia’s Foreign Intelligence Service who has served seven years of an 18-year sentence;and Gennadi Vasilenko, a former K.G.B. major who was arrested in 1998 for contacts with a C.I.A. officer but eventually released only to be arrested again in 2005 and later convicted on illegal weapons charges.\n\n"
    "Within hours of the New York court hearing, the gHULLAgyqBalloo Kremlin announced that President Dmitri A. Medvedev had signed pardons for the four men Russia considered spies after each of them signed statements admitting guilt.\n\n"
    "Drugs, including heroin and a methamphetamine lab, were discovered in the barracks, as was a homemade sex tape that had been circulating among soldiers and that featured one of the brigade’s female lieutenants and five male sergeants.\n\n"
    "“Being back in garrison is what we don’t do well, because since 9/11 it seems we’ve spent more time deployed than at home,” Lt. Col. David Wilson said.\n\n"
    "As the United States military continues to reduce the number of troops in Iraq — to 50,000 by Sept. 1 from about 85,000 now — it has begun to shift some focus to the home front in an effort to ensure a smooth transition for soldiers, a move prompted by lessons learned from returning veterans who have struggled to adjust to lives away from war. Leaders of the Fourth Brigade said its problems had not only been deeply embarrassing, but had revealed institutional ignorance about combat stress and traumatic brain injury that forced the unit to use a holistic approach not typically associated with the military as it confronted its issues.\n\n"
    "“They were leaving a war zone, coming back home and not getting the care and supervision necessary, which allowed them to stay in the Mosul mind-set,” said Sergeant Major Mustafa, referring to the violent northern Iraq city where the brigade had been stationed before it returned to Fort Bliss in 2008. “This is a group of people that had been fighting and killing and taking casualties for 14 months. You can’t switch it on and off.”\n"
    "Deciding When to Use Custom Drawing Code\n\n\n"
    "Depending on the type of application you are creating, it may be possible to use little or no custom drawing code. Although immersive applications typically make extensive use of custom drawing code, utility and productivity applications can often use standard views and controls to display their content.\n\n"
    "The use of custom drawing code should be limited to situations where the content you display needs to change dynamically. For example, a drawing application would need to use custom drawing code to track the user’s drawing commands and a game would be updating the screen constantly to reflect the changing game environment. In those situations, you would need to choose an appropriate drawing technology and create a custom view class to handle events and update the display appropriately.\n\n"
    "On the other hand, if the bulk of your application’s interface is fixed, you can render the interface in advance to one or more image files and display those images at runtime using UIImageView objects. You can layer image views with other content as needed to build your interface. For example, you could use UILabel objects to display configurable text and include buttons or other controls to provide interactivity.\n\n"
    "Improving Drawing Performance\n\n\n"
    "Drawing is a relatively expensive operation on any platform, and optimizing your drawing code should always be an important step in your development process. Table 2-2 lists several tips for ensuring that your drawing code is as optimal as possible. In addition to these tips, you should always use the available performance tools to test your code and remove hotspots and redundancies.\n"
    "The Kremlin identified them as Igor V. Sutyagin, an arms control researcher held for 11 years; Sergei Skripal, a colonel in Russia’s military intelligence service sentenced in 2006 to 13 years for spying for Britain; Aleksandr Zaporozhsky, a former agent with Russia’s Foreign Intelligence Service who has served seven years of an 18-year sentence;and Gennadi Vasilenko, a former K.G.B. major who was arrested in 1998 for contacts with a C.I.A. officer but eventually released only to be arrested again in 2005 and later convicted on illegal weapons charges.\n\n"
    "Within hours of the New York court hearing, the gHULLAgyqBalloo Kremlin announced that President Dmitri A. Medvedev had signed pardons for the four men Russia considered spies after each of them signed statements admitting guilt.\n\n"
    "Drugs, including heroin and a methamphetamine lab, were discovered in the barracks, as was a homemade sex tape that had been circulating among soldiers and that featured one of the brigade’s female lieutenants and five male sergeants.\n\n"
    "“Being back in garrison is what we don’t do well, because since 9/11 it seems we’ve spent more time deployed than at home,” Lt. Col. David Wilson said.\n\n"
    "As the United States military continues to reduce the number of troops in Iraq — to 50,000 by Sept. 1 from about 85,000 now — it has begun to shift some focus to the home front in an effort to ensure a smooth transition for soldiers, a move prompted by lessons learned from returning veterans who have struggled to adjust to lives away from war. Leaders of the Fourth Brigade said its problems had not only been deeply embarrassing, but had revealed institutional ignorance about combat stress and traumatic brain injury that forced the unit to use a holistic approach not typically associated with the military as it confronted its issues.\n\n"
    "“They were leaving a war zone, coming back home and not getting the care and supervision necessary, which allowed them to stay in the Mosul mind-set,” said Sergeant Major Mustafa, referring to the violent northern Iraq city where the brigade had been stationed before it returned to Fort Bliss in 2008. “This is a group of people that had been fighting and killing and taking casualties for 14 months. You can’t switch it on and off.”\n"
    "Deciding When to Use Custom Drawing Code\n\n\n"
    "Depending on the type of application you are creating, it may be possible to use little or no custom drawing code. Although immersive applications typically make extensive use of custom drawing code, utility and productivity applications can often use standard views and controls to display their content.\n\n"
    "The use of custom drawing code should be limited to situations where the content you display needs to change dynamically. For example, a drawing application would need to use custom drawing code to track the user’s drawing commands and a game would be updating the screen constantly to reflect the changing game environment. In those situations, you would need to choose an appropriate drawing technology and create a custom view class to handle events and update the display appropriately.\n\n"
    "On the other hand, if the bulk of your application’s interface is fixed, you can render the interface in advance to one or more image files and display those images at runtime using UIImageView objects. You can layer image views with other content as needed to build your interface. For example, you could use UILabel objects to display configurable text and include buttons or other controls to provide interactivity.\n\n"
    "Improving Drawing Performance\n\n\n"
    "Drawing is a relatively expensive operation on any platform, and optimizing your drawing code should always be an important step in your development process. Table 2-2 lists several tips for ensuring that your drawing code is as optimal as possible. In addition to these tips, you should always use the available performance tools to test your code and remove hotspots and redundancies.\n"
    "FIN";

NSAttributedString *NKTTestText() {
    CTFontRef helvetica = CTFontCreateWithName(CFSTR("Helvetica"), 16.0, nil);
    CGColorRef color = [UIColor blackColor].CGColor;
    NSDictionary *baseAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (id)helvetica, kCTFontAttributeName,
                                    (id)color, kCTForegroundColorAttributeName, nil];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:TestText attributes:baseAttributes];
    
    CTFontRef helveticaBoldItalic = CTFontCreateCopyWithSymbolicTraits(helvetica,
                                                                       16.0,
                                                                       NULL,
                                                                       kCTFontItalicTrait|kCTFontBoldTrait,
                                                                       kCTFontItalicTrait|kCTFontBoldTrait);
    NSDictionary *boldItalicAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          (id)helveticaBoldItalic, kCTFontAttributeName, nil];
    [text setAttributes:boldItalicAttributes range:[[text string] rangeOfString:@"accomplished of explorers"]];
    
    NSDictionary *underlinedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          (id)helvetica, kCTFontAttributeName,
                                          [NSNumber numberWithInt:kCTUnderlineStyleSingle], kCTUnderlineStyleAttributeName, nil];
    [text setAttributes:underlinedAttributes range:[[text string] rangeOfString:@"Stacy"]];
    
    //CTFontRef helveticaBold = CTFontCreateWithName(CFSTR("Helvetica-Bold"), 48.0, nil);
    CTFontRef helveticaBold = CTFontCreateWithName(CFSTR("Zapfino"), 32.0, nil);
    NSDictionary *boldAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    (id)helveticaBold, kCTFontAttributeName,
                                    (id)color, kCTForegroundColorAttributeName, nil];
    [text setAttributes:boldAttributes range:[[text string] rangeOfString:@"The Expedition"]];
    
    CTFontRef markerFelt = CTFontCreateWithName(CFSTR("Marker Felt"), 24.0, nil);
    NSDictionary *headingAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                       (id)markerFelt, kCTFontAttributeName,
                                       (id)color, kCTForegroundColorAttributeName, nil];
    [text setAttributes:headingAttributes range:[[text string] rangeOfString:@"TODO"]];
    [text setAttributes:headingAttributes range:[[text string] rangeOfString:@"Staying Safe"]];
    
    CTFontRef zapfino = CTFontCreateWithName(CFSTR("Zapfino"), 24.0, nil);
    NSDictionary *randomAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      (id)zapfino, kCTFontAttributeName,
                                      (id)color, kCTForegroundColorAttributeName, nil];
    [text setAttributes:randomAttributes range:[[text string] rangeOfString:@"gHULLAgyqBalloo"]];
    
    return [text autorelease];
}
