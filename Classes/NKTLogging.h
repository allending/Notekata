//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//--------------------------------------------------------------------------------------------------
// A simple logging framework.
//--------------------------------------------------------------------------------------------------

#if NKT_LOGGING_DEBUG_ENABLED && !NKT_LOGGING_STRIP_DEBUG

#define NKTLogDebug(...) NSLog(@"%s: %@", __PRETTY_FUNCTION__, __VA_ARGS__)

#else

#define NKTLogDebug(...)

#endif // #if NKT_LOGGING_DEBUG_ENABLED && !NKT_LOGGING_STRIP_DEBUG

#if NKT_LOGGING_WARNING_ENABLED && !NKT_LOGGING_STRIP_WARNING

#define NKTLogWarning(...) NSLog(@"%s: %@", __PRETTY_FUNCTION__, __VA_ARGS__)

#else

#define NKTLogWarning(...)

#endif // #if NKT_LOGGING_WARNING_ENABLED && !NKT_LOGGING_STRIP_WARNING
