//--------------------------------------------------------------------------------------------------
// Copyright 2010 Allen Ding. All rights reserved.
//--------------------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//--------------------------------------------------------------------------------------------------
// A simple logging framework.
//--------------------------------------------------------------------------------------------------

NSString *KBCDetailedCoreDataErrorStringFromError(NSError *error);

void KBCLog(const char *functionName, NSString *fmt, ...);

#define KBCLogTrace() KBCLog(__PRETTY_FUNCTION__, nil)

#if !KBC_LOGGING_DISABLE_DEBUG_OUTPUT

#define KBCLogDebug(...) KBCLog(__PRETTY_FUNCTION__, __VA_ARGS__)

#else

#define KBCLogDebug(...)

#endif

#if !KBC_LOGGING_STRIP_WARNING

#define KBCLogWarning(...) KBCLog(__PRETTY_FUNCTION__, __VA_ARGS__)

#else

#define KBCLogWarning(...)

#endif
