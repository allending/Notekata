//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//--------------------------------------------------------------------------------------------------
// A simple logging framework.
//--------------------------------------------------------------------------------------------------

#if KBC_LOGGING_DEBUG_ENABLED && !KBC_LOGGING_STRIP_DEBUG

#define KBCLogDebug(...) NSLog(@"%s: %@", __PRETTY_FUNCTION__, __VA_ARGS__)

#else

#define KBCLogDebug(...)

#endif // #if KBC_LOGGING_DEBUG_ENABLED && !KBC_LOGGING_STRIP_DEBUG

#if KBC_LOGGING_WARNING_ENABLED && !KBC_LOGGING_STRIP_WARNING

#define KBCLogWarning(...) NSLog(@"%s: %@", __PRETTY_FUNCTION__, __VA_ARGS__)

#else

#define KBCLogWarning(...)

#endif // #if KBC_LOGGING_WARNING_ENABLED && !KBC_LOGGING_STRIP_WARNING
