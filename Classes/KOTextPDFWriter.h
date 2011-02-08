//------------------------------------------------------------------------------
// Copyright 2011 Allen Ding
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

@interface KOTextPDFWriter : NSObject
{
    NSAttributedString *text;
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Initialization
//------------------------------------------------------------------------------

- (id)initWithString:(NSString *)aString;
- (id)initWithAttributedString:(NSAttributedString *)anAttributedString;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Writing PDFs
//------------------------------------------------------------------------------

- (BOOL)writeToFile:(NSString *)path;
- (BOOL)writeToMutableData:(NSMutableData *)mutableData;

@end
