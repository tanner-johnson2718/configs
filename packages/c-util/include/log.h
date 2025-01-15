#ifndef _LOG_H_
#define _LOG_H_

#include <stdio.h>
#include <time.h>
#include <stdarg.h>

#define LOG(tag, format, ...) _log(tag, __LINE__, __func__, format, ##__VA_ARGS__)

void _log(char* tag, int line_no, const char* func, char* format, ...)
{
    time_t now;
    time(&now);
    va_list args;
    va_start(args, format);

    printf("[ %5s ][ %15s:%06d ] ", tag, func, line_no);
    vprintf(format, args);
    printf("\n");

    va_end(args);
}

#endif
